"""Production settings. All security-sensitive values must come from the
environment — this module refuses to start with dev fallbacks."""

from .base import *  # noqa: F401,F403

DEBUG = False

SECRET_KEY = env("SECRET_KEY")
if not SECRET_KEY or SECRET_KEY == "dev-only-insecure-secret-key":
    raise RuntimeError("SECRET_KEY must be set in the environment for production")

ALLOWED_HOSTS = [h.strip() for h in env("ALLOWED_HOSTS", "").split(",") if h.strip()]

CORS_ALLOWED_ORIGINS = [
    o.strip() for o in env("CORS_ALLOWED_ORIGINS", "").split(",") if o.strip()
]

# HTTPS hardening
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 60 * 60 * 24 * 30  # 30 days; raise once stable
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
