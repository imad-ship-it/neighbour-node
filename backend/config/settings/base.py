"""
Base settings shared by all environments.

Environment selection: manage.py defaults to config.settings.dev,
wsgi.py/asgi.py default to config.settings.prod. Override either with the
DJANGO_SETTINGS_MODULE env var. Secrets and machine-specific values come
from backend/.env (see .env.example).
"""

from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

import os

# BASE_DIR = backend/
BASE_DIR = Path(__file__).resolve().parent.parent.parent

load_dotenv(BASE_DIR / ".env")


def env(key, default=None):
    return os.environ.get(key, default)


def env_bool(key, default=False):
    value = env(key)
    if value is None:
        return default
    return value.strip().lower() in ("1", "true", "yes", "on")


# SECURITY WARNING: the fallback key is for local dev only; prod.py requires
# a real SECRET_KEY from the environment.
SECRET_KEY = env("SECRET_KEY", "dev-only-insecure-secret-key")

DEBUG = False

ALLOWED_HOSTS = []

# PostGIS toggle — MASTER_PLAN §8.3. When false, django.contrib.gis stays out
# of INSTALLED_APPS (no GDAL/GEOS needed) and the plain postgres engine is used.
USE_GIS = env_bool("USE_GIS", False)

# Application definition

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "corsheaders",
    "drf_spectacular",
    "django_filters",
]

LOCAL_APPS = [
    "accounts",
    "nodes",
    "items",
    "transactions",
    "chat",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

if USE_GIS:
    INSTALLED_APPS.insert(DJANGO_APPS.index("django.contrib.staticfiles") + 1,
                          "django.contrib.gis")

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# Database — PostgreSQL, with PostGIS engine when USE_GIS is on.
# dev.py adds an optional sqlite fallback (DB_ENGINE=sqlite3).

DATABASES = {
    "default": {
        "ENGINE": (
            "django.contrib.gis.db.backends.postgis"
            if USE_GIS
            else "django.db.backends.postgresql"
        ),
        "NAME": env("DB_NAME", "neighbor_node"),
        "USER": env("DB_USER", "postgres"),
        "PASSWORD": env("DB_PASSWORD", ""),
        "HOST": env("DB_HOST", "localhost"),
        "PORT": env("DB_PORT", "5432"),
    }
}

# Custom user model (MASTER_PLAN §4.1). Placeholder now; real fields land in
# Phase 1. Do NOT run migrate before the accounts initial migration exists.
AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# Internationalization

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True

# Static & media files

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Django REST Framework

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
    ),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Neighbor-Node API",
    "DESCRIPTION": "Hyper-local community-node rental marketplace.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}
