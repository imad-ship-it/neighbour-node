# Neighbor-Node

Neighbor-Node is a hyper-local rental marketplace: people within a 5km radius
rent everyday items — tools, books, electronics, sports gear — from each other.
Its defining feature is the **Node**: a managed physical storeroom (in an
apartment complex, hostel, or co-working space) where a Node Manager witnesses
every pickup and return, verified by a QR-based digital handshake.

## Repo layout

| Directory | Contents |
|---|---|
| [`backend/`](backend/) | Django 5 + DRF + PostgreSQL/PostGIS API |
| [`mobile/`](mobile/) | Flutter app (Clean Architecture, BLoC) |
| [`docs/`](docs/) | Project documentation and decision records |

## Running locally

### Prerequisites

- Python 3.12+ ([python.org](https://www.python.org/downloads/))
- PostgreSQL 16+ ([postgresql.org](https://www.postgresql.org/download/)) —
  remember the `postgres` superuser password you choose during install
- Flutter SDK 3.44+ on PATH ([flutter.dev](https://docs.flutter.dev/get-started/install))
- For the Android emulator: Android Studio with SDK + a device image

### Backend (Django API)

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

Edit `.env`: set `SECRET_KEY` (generate one with
`python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`)
and `DB_PASSWORD` (your postgres password). Then create the database and run:

```powershell
psql -U postgres -c "CREATE DATABASE neighbor_node;"   # or use pgAdmin / SQL Shell
python manage.py migrate
python manage.py createsuperuser    # admin login for /admin
python manage.py runserver
```

Smoke-check: http://127.0.0.1:8000/api/docs/ (Swagger UI) and
http://127.0.0.1:8000/admin/. Run tests with `python manage.py test`.

Settings live in `config/settings/` (`base.py` / `dev.py` / `prod.py`);
`manage.py` uses dev, `wsgi.py`/`asgi.py` use prod. Configuration comes from
`backend/.env` (see `.env.example`).

### Mobile (Flutter app)

```powershell
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen (json models, test mocks)
flutter analyze          # must be clean
flutter test
flutter run              # pick your device: emulator, Chrome, ...
```

#### Google Maps API key (required for the map screen)

The home screen is a Google Map, so Android needs a Maps API key:

1. In the [Google Cloud Console](https://console.cloud.google.com), enable
   **Maps SDK for Android** (APIs & Services → Library), then create an API
   key (→ Credentials). The project needs billing enabled, but native mobile
   map loads sit well inside the free monthly quota. Restrict the key to
   Android apps with package name `com.neighbornode.neighbor_node`.
2. Paste it into `mobile/android/local.properties` (gitignored — the key is
   injected into the manifest at build time and never committed):

   ```properties
   MAPS_API_KEY=AIza...
   ```

3. iOS builds only: also enable **Maps SDK for iOS** and replace
   `YOUR_IOS_MAPS_API_KEY` in `mobile/ios/Runner/AppDelegate.swift`,
   restricting that key to the bundle id.

Without a key the app still runs, but map tiles render blank. On the
emulator, set a mock location (⋮ → Location in extended controls) so the map
has somewhere to centre.

The API host is picked automatically: `localhost:8000` on web/desktop,
`10.0.2.2:8000` on the Android emulator. For a **physical device**, use your
PC's LAN IP and serve Django on all interfaces:

```powershell
python manage.py runserver 0.0.0.0:8000
flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:8000/api/v1
```

When the access token expires mid-session, the Dio auth interceptor refreshes
it transparently — watch for `[AuthInterceptor] ... refreshing access token`
in the debug console. (To see it quickly, temporarily set
`ACCESS_TOKEN_LIFETIME` to a few seconds in `config/settings/dev.py`.)

**GIS toggle (`USE_GIS`, see MASTER_PLAN §8 item 3):** PostGIS needs GDAL/GEOS,
which can be annoying to install on Windows. With `USE_GIS=false` (the default)
the project runs on the plain PostgreSQL engine — or sqlite via `DB_ENGINE=sqlite3`
— and `django.contrib.gis` is left out of `INSTALLED_APPS`, so no GDAL is
required. While GIS is off, models must not use PostGIS fields: location data
is stored as plain lat/lng floats with Haversine filtering, and switches to
`PointField` + PostGIS queries once `USE_GIS=true`.

## Documentation

The source of truth is [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) — project
summary (§1), stack decision (§2), architecture (§3), data models (§4),
API map (§5), and the phase plan (§6).
