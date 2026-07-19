from django.conf import settings

from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import mixins, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from common.geo import bounding_box, haversine_m

from .models import Node
from .permissions import IsNodeManager
from .serializers import (
    NodeCreateSerializer,
    NodeDetailSerializer,
    NodeListSerializer,
)


class NearbyQuerySerializer(serializers.Serializer):
    lat = serializers.FloatField(min_value=-90, max_value=90)
    lng = serializers.FloatField(min_value=-180, max_value=180)
    radius = serializers.FloatField(
        default=5000, min_value=1, max_value=100_000, help_text="Meters"
    )


class NodeViewSet(
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    """Nodes endpoints — MASTER_PLAN §5. No list/delete; PATCH only (no PUT)."""

    queryset = Node.objects.select_related("manager").prefetch_related("photos")
    serializer_class = NodeDetailSerializer
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_serializer_class(self):
        if self.action in ("create", "partial_update"):
            return NodeCreateSerializer
        if self.action == "nearby":
            return NodeListSerializer
        return NodeDetailSerializer

    def get_permissions(self):
        permissions = super().get_permissions()
        if self.action in ("partial_update", "pending_donations"):
            permissions.append(IsNodeManager())
        return permissions

    @extend_schema(request=NodeCreateSerializer, responses={201: NodeDetailSerializer})
    def create(self, request, *args, **kwargs):
        """POST /nodes/ — register a node (inactive until admin approval);
        promotes the creator to NODE_MANAGER."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        node = serializer.save()
        data = NodeDetailSerializer(node, context=self.get_serializer_context()).data
        return Response(data, status=status.HTTP_201_CREATED)

    @extend_schema(request=NodeCreateSerializer, responses=NodeDetailSerializer)
    def partial_update(self, request, *args, **kwargs):
        """PATCH /nodes/{id}/ — manager only."""
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        node = serializer.save()
        data = NodeDetailSerializer(node, context=self.get_serializer_context()).data
        return Response(data)

    @extend_schema(
        parameters=[NearbyQuerySerializer],
        responses=NodeListSerializer(many=True),
    )
    @action(detail=False)
    def nearby(self, request):
        """GET /nodes/nearby/?lat=&lng=&radius=5000 — active nodes within
        radius meters, annotated with distance, nearest first."""
        query = NearbyQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        lat = query.validated_data["lat"]
        lng = query.validated_data["lng"]
        radius = query.validated_data["radius"]

        queryset = self.get_queryset().filter(is_active=True)
        if settings.USE_GIS:
            from django.contrib.gis.db.models.functions import Distance
            from django.contrib.gis.geos import Point
            from django.contrib.gis.measure import D

            point = Point(lng, lat, srid=4326)
            nodes = list(
                queryset.filter(location__dwithin=(point, D(m=radius)))
                .annotate(distance=Distance("location", point))
                .order_by("distance")
            )
            for node in nodes:
                node.distance = node.distance.m
        else:
            min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, radius)
            candidates = queryset.filter(
                latitude__gte=min_lat,
                latitude__lte=max_lat,
                longitude__gte=min_lng,
                longitude__lte=max_lng,
            )
            nodes = []
            for node in candidates:
                distance = haversine_m(lat, lng, node.latitude, node.longitude)
                if distance <= radius:
                    node.distance = distance
                    nodes.append(node)
            nodes.sort(key=lambda node: node.distance)

        serializer = self.get_serializer(nodes, many=True)
        return Response(serializer.data)

    @extend_schema(
        responses=OpenApiResponse(description="ACTIVE + available items at this node")
    )
    @action(detail=True)
    def inventory(self, request, pk=None):
        """GET /nodes/{id}/inventory/ — ACTIVE + available items at this node."""
        from items.models import Item
        from items.serializers import ItemListSerializer

        node = self.get_object()
        items = (
            node.items.filter(
                listing_status=Item.ListingStatus.ACTIVE, is_available=True
            )
            .select_related("owner")
            .prefetch_related("images")
        )
        serializer = ItemListSerializer(
            items, many=True, context=self.get_serializer_context()
        )
        return Response(serializer.data)

    @extend_schema(
        responses=OpenApiResponse(description="This node's donation queue")
    )
    @action(detail=True, url_path="pending-donations")
    def pending_donations(self, request, pk=None):
        """GET /nodes/{id}/pending-donations/ — manager of this node only."""
        from items.models import Item
        from items.serializers import ItemListSerializer

        node = self.get_object()  # IsNodeManager object check runs here
        items = (
            node.items.filter(listing_status=Item.ListingStatus.PENDING_DONATION)
            .select_related("owner")
            .prefetch_related("images")
        )
        serializer = ItemListSerializer(
            items, many=True, context=self.get_serializer_context()
        )
        return Response(serializer.data)
