# Neighbor-Node v2 — Master Project Document

**Hyper-Local Community-Node Rental Marketplace**
**Stack: Flutter · Django REST Framework · PostgreSQL/PostGIS · FCM**
Version 2.0 — Working document. We build phase by phase; each phase ends with a working, testable deliverable.

---

## 1. Project Summary

Neighbor-Node is a mobile app (Android + iOS) that lets people within a 5km radius rent everyday items — tools, books, electronics, sports gear — from each other.

The defining feature is the **Node**: a physical, managed storeroom inside an apartment complex, hostel, or co-working space. Instead of strangers coordinating handoffs at each other's homes, items are donated to and borrowed from the Node, where a trusted **Node Manager** physically witnesses every pickup and return. A QR-based **Digital Handshake** creates a verifiable record of each exchange.

The app supports both flows:

1. **Node flow (primary)** — User donates item to Node → Borrower requests → Manager approves → Borrower picks up from storeroom (QR scan) → returns (QR scan) → both rate.
2. **Personal P2P flow (secondary)** — Classic lender-to-borrower rental, kept for users with no Node nearby.

---

## 2. The Backend Decision — Django + DRF

**Decision: Django + Django REST Framework replaces Firebase as the primary backend.**

### Why this is the right call for this project

| Concern | Firebase | Django + DRF | Winner |
|---|---|---|---|
| Relational data (users ↔ nodes ↔ items ↔ transactions) | Denormalization, no joins, duplicated fields | Foreign keys, joins, aggregates — natural fit | **Django** |
| Transaction state machine enforcement | Complex security rules + Cloud Functions | Permission classes + serializer validation, server-authoritative | **Django** |
| 5km geo queries | Geohash workaround (geoflutterfire), pagination edge cases | PostGIS `dwithin` / `distance_lte` — precise, indexed | **Django** |
| Admin panel (approve Nodes, moderate users) | Build it yourself | Django Admin out of the box | **Django** |
| Node analytics (top items, monthly revenue) | Limited aggregation, needs Cloud Functions | SQL `annotate()` / `aggregate()` | **Django** |
| Team familiarity | New paradigm | You already know DRF | **Django** |
| Real-time chat | Trivial (Firestore streams) | Django Channels + Redis, more setup | Firebase |
| Phone OTP auth | Built-in, free | Twilio (paid) or Firebase-hybrid | Firebase |
| Push notifications | FCM native | Still FCM, called from Django (`fcm-django`) | Tie |
| Hosting | Serverless free tier | Railway/Render + Postgres (~$5–10/mo) | Firebase |
| Offline cache | Built into Firestore SDK | Manual (dio cache interceptor) | Firebase |

### Final stack (hybrid — best of both)

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Clean Architecture, BLoC) |
| API | Django 5 + Django REST Framework |
| Database | PostgreSQL + PostGIS (GeoDjango) |
| Auth | JWT (`djangorestframework-simplejwt`) for sessions; phone OTP via Firebase Auth client-side (token verified in Django) — see §8 |
| Real-time chat | Django Channels + Redis (MVP fallback: REST polling) — see §8 |
| Push notifications | Firebase Cloud Messaging via `fcm-django` |
| Media (item photos) | Django `ImageField` locally in dev → S3/Cloudinary in production |
| API docs | `drf-spectacular` (auto Swagger UI) |

Firebase is **not** removed — it's demoted to exactly two jobs: push notifications and (optionally) phone OTP. Everything else lives in Django where we control it.

---

## 3. System Architecture

```
┌─────────────────────────── FLUTTER APP ───────────────────────────┐
│  Presentation  →  BLoC  →  UseCases  →  Repository (interface)    │
│                                              │                    │
│                                   Data layer: REST DataSources    │
│                                       (dio + JWT interceptor)     │
└──────────────────────────────┬────────────────────────────────────┘
                               │ HTTPS (JSON)          ▲ WebSocket (chat)
                               ▼                       │
┌───────────────────────── DJANGO BACKEND ──────────────────────────┐
│  DRF ViewSets + Serializers + Permission classes                  │
│  Business logic: state machine, QR validation, role checks        │
│  Django Channels (chat consumers)     Django Admin (moderation)   │
└───────┬──────────────────────┬──────────────────────┬─────────────┘
        ▼                      ▼                      ▼
  PostgreSQL + PostGIS       Redis              FCM (push)
  (all app data + geo)    (channels layer)   → user devices
```

### What changes in the Flutter app — and what doesn't

This is where Clean Architecture pays off. **Only the data layer changes.**

| Layer | Change |
|---|---|
| Presentation (pages, BLoCs) | **Unchanged** — BLoCs still fire the same events and receive the same states |
| Domain (entities, use cases, repository interfaces) | **Unchanged** — pure Dart, no backend knowledge |
| Data (datasources, models, repo implementations) | **Rewritten** — Firestore SDK calls become `dio` REST calls; models get `fromJson` matching DRF serializer output |
| Core | Add `api_client.dart` (dio instance + auth interceptor + error mapping) |

### Flutter dependency changes

| Removed | Added / Kept |
|---|---|
| `cloud_firestore` | `dio` (kept — now the main network client) |
| `firebase_storage` | `pretty_dio_logger` (dev) |
| `geoflutterfire_plus` | `web_socket_channel` (Phase 5, chat) |
| `firebase_auth` (moved to optional, OTP only) | `firebase_core` + `firebase_messaging` (kept, FCM only) |
| — | `json_annotation` + `json_serializable` (model codegen) |
| — | `google_maps_flutter`, `geolocator`, `geocoding` (all kept) |
| — | `flutter_bloc`, `get_it`, `go_router`, `qr_flutter`, `mobile_scanner` (all kept) |

### Backend dependencies (`requirements.txt`)

```
django>=5.0
djangorestframework
djangorestframework-simplejwt
django-cors-headers
drf-spectacular
psycopg2-binary
django-filter
pillow
fcm-django
firebase-admin          # only if using Firebase phone-OTP hybrid
channels                # Phase 5
channels-redis          # Phase 5
daphne                  # Phase 5 (ASGI server)
gunicorn                # Phase 6 (deployment)
whitenoise              # Phase 6 (static files)
```

---

## 4. Database Design — Django Models

All models use PostGIS `PointField` for coordinates. Timestamps (`created_at`, `updated_at`) exist on every model and are omitted from tables below for brevity.

### 4.1 `User` (extends `AbstractUser`) — app: `accounts`

| Field | Type | Notes |
|---|---|---|
| `username` / `email` / `password` | inherited | Email used as login identifier |
| `phone_number` | CharField, unique, null | With country code, e.g. `+92300...` |
| `is_phone_verified` | BooleanField | Set after OTP verification |
| `photo` | ImageField, null | Profile photo |
| `role` | CharField(choices) | `USER` \| `NODE_MANAGER` |
| `rating` | DecimalField(3,2) | Running average 0.00–5.00 |
| `total_rentals` | PositiveIntegerField | Count as borrower |
| `total_lendings` | PositiveIntegerField | Count as lender/donor |
| `location` | PointField, null | Last known location, updated on app open |
| `address` | CharField | Human-readable, e.g. "F-7, Islamabad" |
| `fcm_token` | CharField, null | For push notifications |
| `is_id_verified` | BooleanField | Optional manual ID check |

### 4.2 `Node` — app: `nodes`

| Field | Type | Notes |
|---|---|---|
| `manager` | ForeignKey(User) | The Node Manager. `user.managed_nodes` reverse |
| `name` | CharField | e.g. "Block C Storeroom" |
| `description` | TextField | |
| `address` | CharField | Public display address |
| `location` | PointField | Exact storeroom coordinates |
| `operating_hours` | JSONField | `{"mon": "9:00-18:00", ...}` |
| `capacity` | PositiveIntegerField | Max items the room holds |
| `is_active` | BooleanField, default False | **Approved by admin via Django Admin** |
| `rating` | DecimalField(3,2) | Avg of node ratings |
| `total_transactions` | PositiveIntegerField | Running counter |

`NodePhoto`: `node` FK, `image` ImageField, `order` (up to 3 photos).

### 4.3 `Item` — app: `items`

| Field | Type | Notes |
|---|---|---|
| `owner` | ForeignKey(User) | Original owner (even when donated) |
| `node` | ForeignKey(Node), null | Null = personal P2P item |
| `storage_type` | CharField(choices) | `PERSONAL` \| `NODE` |
| `listing_status` | CharField(choices) | `PENDING_DONATION` \| `ACTIVE` \| `REJECTED` \| `ARCHIVED` |
| `title` | CharField | e.g. "DeWalt Power Drill" |
| `description` | TextField | |
| `category` | CharField(choices) | `TOOLS` \| `BOOKS` \| `ELECTRONICS` \| `SPORTS` \| `OTHER` |
| `condition` | CharField(choices) | `NEW` \| `GOOD` \| `FAIR` \| `POOR` |
| `daily_rate` | DecimalField(8,2) | PKR |
| `deposit_amount` | DecimalField(8,2) | Security deposit |
| `is_available` | BooleanField | Toggled automatically by transaction flow |
| `location` | PointField | Copied from Node (if node item) or owner |

`ItemImage`: `item` FK, `image` ImageField, `order` (up to 5 photos).

**Donation flow:** creating an item with a `node` set → `listing_status = PENDING_DONATION`. Manager accepts → `ACTIVE`. Manager rejects → `REJECTED`.

### 4.4 `Transaction` — app: `transactions`

| Field | Type | Notes |
|---|---|---|
| `item` | ForeignKey(Item) | |
| `node` | ForeignKey(Node), null | Set if Node transaction |
| `lender` | ForeignKey(User) | = item.owner at creation |
| `borrower` | ForeignKey(User) | |
| `handled_by` | ForeignKey(User), null | Node Manager who processes handoffs |
| `status` | CharField(choices) | See state machine below |
| `start_date` / `end_date` | DateField | Requested rental window |
| `total_cost` | DecimalField(10,2) | days × daily_rate, computed server-side |
| `deposit_amount` | DecimalField(8,2) | Snapshot at creation |
| `pickup_qr_code` | UUIDField, null | Generated on ACCEPTED |
| `return_qr_code` | UUIDField, null | Generated on ACCEPTED |
| `pickup_confirmed_at` | DateTimeField, null | Set on valid pickup scan |
| `return_confirmed_at` | DateTimeField, null | Set on valid return scan |
| `cancelled_by` | ForeignKey(User), null | |
| `cancel_reason` | CharField, null | |

**State machine (enforced in serializer/view, never trusted from client):**

```
PENDING ──accept──► ACCEPTED ──scan pickup QR──► PICKED_UP ──scan return QR──► RETURNED ──both rated──► COMPLETED
   │                    │
   └────cancel──────────┴────► CANCELLED
```

| Transition | Who may trigger it | Server-side check |
|---|---|---|
| PENDING → ACCEPTED | Node Manager (node tx) or Lender (P2P) | `request.user == node.manager` or `== lender`; generates both QR UUIDs |
| PENDING/ACCEPTED → CANCELLED | Borrower, or the approver | Must be before pickup |
| ACCEPTED → PICKED_UP | `handled_by` (manager) or lender | Scanned code must equal `pickup_qr_code`; sets `is_available=False` |
| PICKED_UP → RETURNED | Same | Scanned code must equal `return_qr_code`; sets `is_available=True` |
| RETURNED → COMPLETED | Automatic | When both ratings exist, or after 48h |

### 4.5 `ChatRoom` + `Message` — app: `chat`

| Model | Fields |
|---|---|
| `ChatRoom` | `transaction` OneToOne(Transaction) — one chat per rental; `participants` implied by transaction roles |
| `Message` | `room` FK, `sender` FK(User), `text`, `image` (null), `is_read` Bool, `sent_at` |

One chat per transaction keeps context clean and permissioning trivial (only lender, borrower, manager may read/write).

### 4.6 `Rating` — app: `transactions`

| Field | Type | Notes |
|---|---|---|
| `transaction` | ForeignKey(Transaction) | |
| `rater` | ForeignKey(User) | |
| `ratee_user` | ForeignKey(User), null | Rating a person |
| `ratee_node` | ForeignKey(Node), null | Rating a Node |
| `score` | PositiveSmallIntegerField | 1–5, validated |
| `comment` | TextField, blank | |
| unique constraint | (`transaction`, `rater`) | One rating per person per transaction |

On save, a signal recalculates the ratee's running average.

---

## 5. Complete API Endpoint Map

All endpoints prefixed `/api/v1/`. Auth = JWT Bearer unless noted.

### Auth (`accounts`)

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| POST | `/auth/register/` | Public | Email + password signup, returns JWT pair |
| POST | `/auth/login/` | Public | Returns `access` + `refresh` tokens |
| POST | `/auth/refresh/` | Public | Refresh access token |
| POST | `/auth/verify-phone/` | Auth | Firebase ID token in → verifies via `firebase-admin` → sets `is_phone_verified` |
| GET/PATCH | `/auth/me/` | Auth | Get/update own profile, upload photo, update `location` + `fcm_token` |

### Nodes

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| GET | `/nodes/nearby/?lat=&lng=&radius=5000` | Auth | PostGIS `dwithin` query, active nodes only |
| POST | `/nodes/` | Auth | Register a Node → creator's role becomes `NODE_MANAGER`; `is_active=False` until admin approves |
| GET | `/nodes/{id}/` | Auth | Node detail + operating hours + rating |
| PATCH | `/nodes/{id}/` | Manager only | Update hours, photos, description |
| GET | `/nodes/{id}/inventory/` | Auth | All `ACTIVE` + available items at this Node |
| GET | `/nodes/{id}/stats/` | Manager only | Monthly transactions, top items, revenue |

### Items

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| GET | `/items/nearby/?lat=&lng=&radius=5000&category=&max_rate=` | Auth | Geo + filter query |
| POST | `/items/` | Auth | Create item (multipart with images). If `node` set → `PENDING_DONATION` |
| GET/PATCH/DELETE | `/items/{id}/` | Owner (or manager for node items) | |
| GET | `/items/my/` | Auth | Own listings |
| GET | `/nodes/{id}/pending-donations/` | Manager only | Donation queue |
| POST | `/items/{id}/review-donation/` | Manager only | Body: `{"action": "accept" \| "reject"}` |

### Transactions

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| POST | `/transactions/` | Auth | Create rental request (`status=PENDING`), server computes `total_cost` |
| GET | `/transactions/my/?role=borrower\|lender\|manager` | Auth | Own transactions by role |
| GET | `/transactions/{id}/` | Participant | Detail incl. QR codes (borrower sees own QRs only) |
| POST | `/transactions/{id}/accept/` | Manager/Lender | PENDING → ACCEPTED, generates QR UUIDs, FCM to borrower |
| POST | `/transactions/{id}/cancel/` | Participant | → CANCELLED with reason |
| POST | `/transactions/{id}/confirm-pickup/` | Manager/Lender | Body: `{"qr_code": "..."}` → validated → PICKED_UP |
| POST | `/transactions/{id}/confirm-return/` | Manager/Lender | Body: `{"qr_code": "..."}` → validated → RETURNED |
| POST | `/transactions/{id}/rate/` | Participant | Creates `Rating`, may auto-complete transaction |

### Chat

| Method | Endpoint | Permission | Purpose |
|---|---|---|---|
| GET | `/chats/` | Auth | My chat rooms (via my transactions) |
| GET | `/chats/{room_id}/messages/?before=` | Participant | Paginated history |
| POST | `/chats/{room_id}/messages/` | Participant | Send (REST fallback) |
| WS | `/ws/chat/{room_id}/` | Participant (JWT in query) | Real-time via Channels (Phase 5) |

---

## 6. Development Phases

Each phase = one sprint. I provide logic + structure + code; you build, confirm it works, we move on. Backend and Flutter tasks are interleaved so every phase ends with something you can tap on a phone.

---

### PHASE 1 — Backend Foundation + Auth (both sides)

**Goal:** A running Django API and a Flutter app where a user can register, log in, and stay logged in.

**Backend tasks**
1. `django-admin startproject config` + apps: `accounts`, `nodes`, `items`, `transactions`, `chat`
2. PostgreSQL + PostGIS setup, `django.contrib.gis` enabled (see §8 for the GDAL note)
3. Custom `User` model (§4.1) — must be done before first migration
4. SimpleJWT configuration: access 60min, refresh 7 days, rotation on
5. Endpoints: register, login, refresh, `/auth/me/`
6. `drf-spectacular` — Swagger UI at `/api/docs/`
7. CORS headers configured for development
8. Register `User` in Django Admin with search + role filter

**Flutter tasks**
1. Project scaffold — full Clean Architecture folder tree (auth, nodes, items, transactions, chat, dashboard features + core)
2. `core/network/api_client.dart` — dio instance with base URL, JWT interceptor (attach access token, auto-refresh on 401, logout on refresh failure)
3. `core/errors/` — map DRF error responses → `Failure` types via dartz `Either`
4. Auth feature: datasource → repository impl → use cases (`RegisterUser`, `LoginUser`, `GetCurrentUser`, `Logout`) → `AuthBloc` → Login/Register pages
5. Token persistence in `flutter_secure_storage`; splash screen decides route by token validity
6. `injection_container.dart` — GetIt registrations for everything above

**Definition of done:** Register on the phone → see the user in Django Admin → kill app → reopen → still logged in → token silently refreshes.

---

### PHASE 2 — Nodes + Map

**Goal:** Nodes exist, are approved via admin, and appear as gold markers on a live Google Map.

**Backend tasks**
1. `Node` + `NodePhoto` models, serializers, ViewSet
2. `/nodes/nearby/` — GeoDjango: `Node.objects.filter(is_active=True, location__dwithin=(user_point, D(m=radius)))` annotated with distance, ordered nearest-first
3. Register-Node endpoint: creates Node (`is_active=False`), promotes creator to `NODE_MANAGER`
4. Django Admin action: "Approve selected nodes" (sets `is_active=True`, fires FCM later)
5. Multipart photo upload for Node photos

**Flutter tasks**
1. `geolocator` — permission flow + current position; send location to `/auth/me/` on app open
2. `MapPage` — `google_maps_flutter`, camera on user, 5km radius circle overlay
3. `NodeBloc` — `GetNearbyNodesEvent` → REST call → gold custom markers
4. Node detail page (photos, hours, rating, distance)
5. Register-Node form (name, address via `geocoding`, hours picker, photos via `image_picker`)

**Definition of done:** Register a Node on phone A → approve in Django Admin → phone B refreshes map → gold marker appears → tap → detail page.

---

### PHASE 3 — Items + Donations

**Goal:** Full item lifecycle — list personally, donate to a Node, manager approves, items appear on map and in Node inventory.

**Backend tasks**
1. `Item` + `ItemImage` models, multipart create endpoint (up to 5 images)
2. `/items/nearby/` with `django-filter` (category, max_rate) on top of the geo query
3. Donation queue endpoints: pending list + accept/reject action (manager permission class `IsNodeManagerOfItem`)
4. `/nodes/{id}/inventory/`

**Flutter tasks**
1. Add-Item page — multi-image picker with previews, category dropdown, rate/deposit inputs, storage choice: "Keep at my place" vs "Donate to a Node" (Node picker sorted by distance)
2. `ItemsBloc` — nearby items as blue markers layered with gold Node markers; filter bar re-queries
3. Item detail page (photo carousel via `cached_network_image`, owner rating, rate, condition)
4. Manager screen: pending donations list with Accept / Reject
5. Node inventory grid inside Node detail page

**Definition of done:** Phone A donates a drill to a Node → manager (phone B) accepts → phone C sees it in the Node's inventory and on the map, filterable by category.

---

### PHASE 4 — Transactions + QR Digital Handshake

**Goal:** Complete rental loop between two phones, with the state machine enforced server-side and QR scans confirming pickup and return.

**Backend tasks**
1. `Transaction` model + create endpoint (validates availability + date overlap against existing ACCEPTED/PICKED_UP transactions; computes `total_cost`)
2. Transition endpoints (`accept`, `cancel`, `confirm-pickup`, `confirm-return`) — each a small action with an explicit permission check per the matrix in §4.4; QR UUIDs generated with `uuid.uuid4()` on accept
3. QR validation: scanned string must match the stored UUID for that exact transaction and status — anything else → 400 with clear error
4. `item.is_available` toggled inside the same DB transaction (`transaction.atomic`)
5. `Rating` model + rate endpoint + signal recalculating averages; auto-COMPLETED when both ratings exist

**Flutter tasks**
1. Request-rental flow: date-range picker → live cost calc → submit
2. `TransactionBloc` + statuses timeline UI on transaction detail
3. Manager dashboard: tabs for Pending Requests / Active Rentals / Due Today
4. `QrDisplayPage` (borrower) — `qr_flutter` renders the UUID
5. `QrScannerPage` (manager/lender) — `mobile_scanner` → `ConfirmPickup`/`ConfirmReturn` use case → success/failure animation
6. Rating dialog triggered on RETURNED

**Definition of done:** Phone A requests → manager phone B accepts → A shows pickup QR → B scans → status flips on both phones → same for return → both rate → COMPLETED, averages updated.

---

### PHASE 5 — Chat + Push Notifications

**Goal:** Real-time messaging per transaction and push notifications for every important event.

**Backend tasks**
1. `ChatRoom` auto-created on transaction creation (signal); `Message` model + REST history endpoint
2. Django Channels: Redis channel layer, `ChatConsumer` (JWT auth middleware on websocket), room group per transaction
3. `fcm-django` device registration endpoint; notification triggers on: new request, accepted, pickup confirmed, return due tomorrow, return confirmed, new message
4. ASGI config with Daphne

**Flutter tasks**
1. Chat UI — bubbles, timestamps, read state; `web_socket_channel` connection with reconnect logic; REST history for backfill
2. `firebase_messaging` — foreground banner, background tap → `go_router` deep link to the right transaction/chat
3. FCM token registered to backend on login and token-refresh

**Definition of done:** Message sent on phone A appears instantly on phone B; phone B locked → still gets a push; tapping the push opens that exact chat.

> MVP fallback if Channels fights us: 5-second REST polling on the open chat screen, upgrade to websockets after. The Flutter repository interface stays identical either way — only the datasource changes.

---

### PHASE 6 — Analytics, Polish + Deployment

**Goal:** Production backend, store-ready builds.

**Backend tasks**
1. `/nodes/{id}/stats/` — SQL aggregates: transactions/month, revenue, top 5 items
2. Media to S3 or Cloudinary (`django-storages`)
3. Dockerfile + `docker-compose` (web, db, redis); deploy to Railway or Render; env-var settings split (dev/prod); `DEBUG=False`, allowed hosts, HTTPS
4. Gunicorn (HTTP) + Daphne (WS) behind the platform's proxy
5. Basic rate limiting (DRF throttles) + admin hardening

**Flutter tasks**
1. Node analytics screen (charts) for managers
2. App icon, splash, empty/error/loading states audit, shimmer skeletons
3. Release config: Android signing + `--release` AAB, iOS archive
4. Point base URL at production API via flavors (`dev` / `prod`)

**Definition of done:** APK on a real phone talking to the deployed backend performs the entire Phase 4 loop.

---

## 7. What Changed From the Firebase Plan

| Area | Was (Firebase) | Now (Django) |
|---|---|---|
| Data | Firestore collections | PostgreSQL tables with FKs |
| Geo queries | geohash via geoflutterfire | PostGIS `dwithin` |
| Business rules | Security rules + Cloud Functions | DRF serializers + permission classes |
| Node approval | Custom-built admin screen | Django Admin (free) |
| Auth session | Firebase SDK | JWT (SimpleJWT) |
| Phone OTP | Firebase Auth | Firebase Auth kept *only* for this (or Twilio) |
| Chat | Firestore streams | Django Channels (or polling MVP) |
| Push | FCM | FCM (unchanged, triggered from Django) |
| Flutter impact | — | Data layer rewritten; domain + presentation untouched |

---

## 8. Open Decisions & Risks (we decide these at the phase where they bite)

1. **Phone OTP provider (decide in Phase 1).** Recommended: keep `firebase_auth` in Flutter purely for OTP; app sends the Firebase ID token to `/auth/verify-phone/`; Django verifies with `firebase-admin` and marks `is_phone_verified`. Zero cost. Alternative: Twilio Verify (paid). MVP fallback: email/password only, add phone in Phase 6.
2. **Chat transport (decide in Phase 5).** Recommended: Django Channels. Fallback: REST polling. The Flutter repository interface is identical either way.
3. **GeoDjango setup friction.** PostGIS needs GDAL/GEOS installed locally — trivial on Linux/Mac, occasionally annoying on Windows. Fallback if it blocks you: plain `FloatField` lat/lng + bounding-box filter + Haversine in Python for MVP, migrate to PostGIS at deploy. Say the word and I'll give that variant.
4. **Payments are out of scope for v1.** Cash on pickup; the app records `total_cost` and `deposit_amount` as a ledger. Online payments (Stripe/JazzCash/Easypaisa) become a v2 phase.
5. **Media storage.** Local `MEDIA_ROOT` in dev is fine; must move to S3/Cloudinary before production (Phase 6).

---

## 9. How We Work (Sprint Protocol)

1. We start a phase → I give you the logic, folder structure, and code for that phase only.
2. You build it, run it, and test the Definition of Done.
3. You confirm ("working, understood") → we move to the next phase. Questions and bugs are handled inside the phase before moving on.
4. Any architecture change request (like this Django switch) gets an impact assessment first, then this document is updated so it always reflects reality.

**Current status: Ready to start Phase 1 — Django project setup + custom User model + JWT auth + Flutter scaffold.**
