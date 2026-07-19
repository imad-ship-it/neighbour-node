from rest_framework.routers import SimpleRouter

from .views import ItemViewSet

app_name = "items"

router = SimpleRouter()
router.register("", ItemViewSet, basename="item")

urlpatterns = router.urls
