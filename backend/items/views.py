from django.conf import settings

from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from common.geo import bounding_box, haversine_m
from nodes.views import NearbyQuerySerializer

from .filters import ItemFilter
from .models import Item
from .permissions import IsNodeManagerOfItem, IsOwnerOrNodeManager
from .serializers import (
    ItemCreateSerializer,
    ItemDetailSerializer,
    ItemListSerializer,
    ItemUpdateSerializer,
    ReviewDonationSerializer,
)


class ItemViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    """Items endpoints — MASTER_PLAN §5. No list; PATCH only (no PUT)."""

    queryset = Item.objects.select_related("owner", "node").prefetch_related(
        "images"
    )
    serializer_class = ItemDetailSerializer
    http_method_names = ["get", "post", "patch", "delete", "head", "options"]

    def get_serializer_class(self):
        return {
            "create": ItemCreateSerializer,
            "partial_update": ItemUpdateSerializer,
            "nearby": ItemListSerializer,
            "my": ItemListSerializer,
            "review_donation": ReviewDonationSerializer,
        }.get(self.action, ItemDetailSerializer)

    def get_permissions(self):
        permissions = super().get_permissions()
        if self.action in ("partial_update", "destroy"):
            permissions.append(IsOwnerOrNodeManager())
        elif self.action == "review_donation":
            permissions.append(IsNodeManagerOfItem())
        return permissions

    def _detail_response(self, item, status_code=status.HTTP_200_OK):
        data = ItemDetailSerializer(
            item, context=self.get_serializer_context()
        ).data
        return Response(data, status=status_code)

    @extend_schema(request=ItemCreateSerializer, responses={201: ItemDetailSerializer})
    def create(self, request, *args, **kwargs):
        """POST /items/ — multipart; `node` set → PENDING_DONATION."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return self._detail_response(serializer.save(), status.HTTP_201_CREATED)

    @extend_schema(request=ItemUpdateSerializer, responses=ItemDetailSerializer)
    def partial_update(self, request, *args, **kwargs):
        """PATCH /items/{id}/ — owner, or node's manager for node items."""
        serializer = self.get_serializer(
            self.get_object(), data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        return self._detail_response(serializer.save())

    @extend_schema(
        parameters=[NearbyQuerySerializer, ItemFilter],
        responses=ItemListSerializer(many=True),
    )
    @action(detail=False)
    def nearby(self, request):
        """GET /items/nearby/?lat=&lng=&radius=&category=&max_rate=&storage_type=
        — ACTIVE + available items within radius, nearest first."""
        query = NearbyQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        lat = query.validated_data["lat"]
        lng = query.validated_data["lng"]
        radius = query.validated_data["radius"]

        queryset = self.get_queryset().filter(
            listing_status=Item.ListingStatus.ACTIVE, is_available=True
        )
        queryset = ItemFilter(request.query_params, queryset=queryset).qs

        if settings.USE_GIS:
            from django.contrib.gis.db.models.functions import Distance
            from django.contrib.gis.geos import Point
            from django.contrib.gis.measure import D

            point = Point(lng, lat, srid=4326)
            items = list(
                queryset.filter(location__dwithin=(point, D(m=radius)))
                .annotate(distance=Distance("location", point))
                .order_by("distance")
            )
            for item in items:
                item.distance = item.distance.m
        else:
            min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, radius)
            candidates = queryset.filter(
                latitude__gte=min_lat,
                latitude__lte=max_lat,
                longitude__gte=min_lng,
                longitude__lte=max_lng,
            )
            items = []
            for item in candidates:
                distance = haversine_m(lat, lng, item.latitude, item.longitude)
                if distance <= radius:
                    item.distance = distance
                    items.append(item)
            items.sort(key=lambda item: item.distance)

        serializer = self.get_serializer(items, many=True)
        return Response(serializer.data)

    @extend_schema(responses=ItemListSerializer(many=True))
    @action(detail=False)
    def my(self, request):
        """GET /items/my/ — own listings, every status (incl. pending)."""
        items = self.get_queryset().filter(owner=request.user)
        return Response(self.get_serializer(items, many=True).data)

    @extend_schema(
        request=ReviewDonationSerializer, responses=ItemDetailSerializer
    )
    @action(detail=True, methods=["post"], url_path="review-donation")
    def review_donation(self, request, pk=None):
        """POST /items/{id}/review-donation/ — manager only;
        accept → ACTIVE, reject → REJECTED (§4.3 donation flow)."""
        item = self.get_object()
        if item.listing_status != Item.ListingStatus.PENDING_DONATION:
            return Response(
                {"detail": "This item is not awaiting donation review."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        accepted = serializer.validated_data["action"] == "accept"
        item.listing_status = (
            Item.ListingStatus.ACTIVE if accepted else Item.ListingStatus.REJECTED
        )
        item.save(update_fields=["listing_status", "updated_at"])
        return self._detail_response(item)
