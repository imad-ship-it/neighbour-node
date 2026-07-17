# Neighbor-Node

Hyper-local rental marketplace: Flutter mobile app + Django REST backend.
Users rent items within 5km, either P2P or via managed community "Nodes"
(physical storerooms run by a Node Manager) with a QR pickup/return handshake.

**SOURCE OF TRUTH: `docs/MASTER_PLAN.md`.** Data models are in §4, API map in §5,
phase plan in §6, transaction state machine + permission matrix in §4.4.
Read the relevant section before implementing anything.

## Repo layout
- `backend/`  — Django 5 + DRF + PostgreSQL/PostGIS. Apps: accounts, nodes, items, transactions, chat
- `mobile/`   — Flutter app, Clean Architecture (data / domain / presentation per feature), BLoC, GetIt, go_router
- `docs/`     — MASTER_PLAN.md and any decision records

## Commands
Backend (run from `backend/`, venv active):
- Run server: `python manage.py runserver`
- Migrations: `python manage.py makemigrations && python manage.py migrate`
- Tests: `python manage.py test`
- New deps: add to `requirements.txt`, then `pip install -r requirements.txt`

Mobile (run from `mobile/`):
- Run: `flutter run`
- Analyze: `flutter analyze` (must be clean before any commit)
- Tests: `flutter test`
- Codegen: `dart run build_runner build --delete-conflicting-outputs`

## Hard rules
1. NEVER trust the client for transaction state transitions. Every transition is
   validated server-side per the matrix in MASTER_PLAN §4.4, with an explicit
   DRF permission class. QR codes are validated against the stored UUID.
2. Flutter dependency rule: presentation → domain ← data. Domain layer has NO
   Flutter/dio/backend imports. Data layer implements domain repository
   interfaces. All errors cross layers as `Either<Failure, T>` (dartz).
3. Backend: every new endpoint gets a serializer, an explicit permission class,
   and at least one test. Use ViewSets + routers. Money = DecimalField, never float.
4. Never commit secrets. `.env` files are gitignored; ship `.env.example` instead.
5. Migrations are committed with the code that needs them. Never edit an
   applied migration.
6. After backend changes run `python manage.py test`; after Flutter changes run
   `flutter analyze`. Fix everything before declaring done.
7. Match existing patterns. Before writing a new file, read a sibling
   (e.g. new feature bloc → read auth bloc first).