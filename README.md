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

## Backend setup

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env       # then edit values
python manage.py check
```

Settings live in `config/settings/` (`base.py` / `dev.py` / `prod.py`);
`manage.py` uses dev, `wsgi.py`/`asgi.py` use prod. Configuration comes from
`backend/.env` (see `.env.example`).

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
