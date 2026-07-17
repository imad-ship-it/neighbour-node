"""Development settings."""

from .base import *  # noqa: F401,F403

DEBUG = True

ALLOWED_HOSTS = ["*"]

# Dev only — never enable allow-all CORS in production (prod.py uses an
# explicit CORS_ALLOWED_ORIGINS list).
CORS_ALLOW_ALL_ORIGINS = True

# ---------------------------------------------------------------------------
# Database fallback (MASTER_PLAN §8.3 — GeoDjango setup friction on Windows)
#
# Three modes, controlled from .env:
#   1. USE_GIS=true              → PostGIS engine (needs PostGIS + GDAL/GEOS
#                                  installed). The target setup.
#   2. USE_GIS=false (default)   → plain django.db.backends.postgresql, no
#                                  GDAL needed. Geo features are stubbed until
#                                  PostGIS is ready (plain lat/lng fields +
#                                  Haversine filtering per §8.3).
#   3. DB_ENGINE=sqlite3         → local file db.sqlite3, no Postgres install
#                                  at all. Quickest way to run checks/tests on
#                                  a fresh machine. Only valid with
#                                  USE_GIS=false (sqlite has no PostGIS).
# ---------------------------------------------------------------------------
if env("DB_ENGINE", "").strip().lower() == "sqlite3":
    if USE_GIS:
        raise RuntimeError("DB_ENGINE=sqlite3 requires USE_GIS=false")
    DATABASES["default"] = {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
