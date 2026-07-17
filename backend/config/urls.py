"""Root URL configuration.

All API endpoints live under /api/v1/ (MASTER_PLAN §5). Interactive docs at
/api/docs/ (Swagger UI via drf-spectacular).
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

# App routers get included here as they land, e.g.:
#   path("auth/", include("accounts.urls")),
#   path("nodes/", include("nodes.urls")),
#   path("items/", include("items.urls")),
#   path("transactions/", include("transactions.urls")),
#   path("chat/", include("chat.urls")),
api_v1_patterns = []

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path("api/v1/", include(api_v1_patterns)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
