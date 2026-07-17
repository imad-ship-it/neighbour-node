import json
import re

from django.conf import settings
from django.db import transaction

from rest_framework import serializers

from accounts.models import User

from .models import DAY_KEYS, Node, NodePhoto

# "H:MM-HH:MM" — hours 0-23 (1 or 2 digits), minutes 00-59.
TIME_RANGE_RE = re.compile(r"^([01]?\d|2[0-3]):[0-5]\d-([01]?\d|2[0-3]):[0-5]\d$")


def location_dict(obj):
    """Serialize a location as {"lat": ..., "lng": ...} in either GIS mode."""
    loc = obj.location
    if loc is None:
        return None
    if settings.USE_GIS:
        return {"lat": loc.y, "lng": loc.x}
    return {"lat": loc[0], "lng": loc[1]}


class NodePhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = NodePhoto
        fields = ("id", "image", "order")


class ManagerPublicSerializer(serializers.ModelSerializer):
    """Public subset of the manager's profile for node detail responses."""

    display_name = serializers.CharField(source="first_name", read_only=True)

    class Meta:
        model = User
        fields = ("id", "display_name", "photo", "rating")


class NodeListSerializer(serializers.ModelSerializer):
    """Compact node payload for /nodes/nearby/ map markers."""

    location = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    thumbnail = serializers.SerializerMethodField()
    is_open_now = serializers.SerializerMethodField()

    class Meta:
        model = Node
        fields = (
            "id",
            "name",
            "address",
            "location",
            "rating",
            "distance",
            "thumbnail",
            "is_open_now",
        )

    def get_location(self, obj) -> dict:
        return location_dict(obj)

    def get_distance(self, obj) -> float | None:
        """Meters from the query point; set by the nearby view."""
        distance = getattr(obj, "distance", None)
        return None if distance is None else round(distance, 1)

    def get_thumbnail(self, obj) -> str | None:
        photo = next(iter(obj.photos.all()), None)
        if photo is None:
            return None
        url = photo.image.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request else url

    def get_is_open_now(self, obj) -> bool:
        return obj.is_open_now()


class NodeDetailSerializer(serializers.ModelSerializer):
    """Full node payload for detail views and create/update responses."""

    location = serializers.SerializerMethodField()
    is_open_now = serializers.SerializerMethodField()
    photos = NodePhotoSerializer(many=True, read_only=True)
    manager = ManagerPublicSerializer(read_only=True)

    class Meta:
        model = Node
        fields = (
            "id",
            "name",
            "description",
            "address",
            "location",
            "operating_hours",
            "capacity",
            "is_active",
            "rating",
            "total_transactions",
            "is_open_now",
            "photos",
            "manager",
            "created_at",
        )

    def get_location(self, obj) -> dict:
        return location_dict(obj)

    def get_is_open_now(self, obj) -> bool:
        return obj.is_open_now()


class NodeCreateSerializer(serializers.ModelSerializer):
    """Input serializer for POST /nodes/ and PATCH /nodes/{id}/.

    Coordinates come in as latitude/longitude and land on either the
    PointField (USE_GIS on) or the float columns (off). Photos arrive as
    multipart files (max 3) and replace the existing set on update.
    """

    latitude = serializers.FloatField(
        write_only=True, min_value=-90, max_value=90
    )
    longitude = serializers.FloatField(
        write_only=True, min_value=-180, max_value=180
    )
    photos = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=False,
        max_length=3,
        error_messages={"max_length": "A node can have at most 3 photos."},
    )

    class Meta:
        model = Node
        fields = (
            "name",
            "description",
            "address",
            "latitude",
            "longitude",
            "operating_hours",
            "capacity",
            "photos",
        )
        extra_kwargs = {"operating_hours": {"required": True}}

    def validate_operating_hours(self, value):
        # Multipart clients send JSON as a string; parse it first.
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                raise serializers.ValidationError("Must be valid JSON.")
        if not isinstance(value, dict):
            raise serializers.ValidationError(
                'Must be an object like {"mon": "09:00-18:00", ..., "sun": "closed"}.'
            )
        missing = [day for day in DAY_KEYS if day not in value]
        if missing:
            raise serializers.ValidationError(
                f"Missing day(s): {', '.join(missing)}. All of mon-sun are required."
            )
        unknown = [key for key in value if key not in DAY_KEYS]
        if unknown:
            raise serializers.ValidationError(
                f"Unknown key(s): {', '.join(unknown)}. Use mon, tue, wed, thu, fri, sat, sun."
            )
        for day, hours in value.items():
            if not isinstance(hours, str) or (
                hours.strip().lower() != "closed"
                and not TIME_RANGE_RE.match(hours.strip())
            ):
                raise serializers.ValidationError(
                    f'Invalid value for "{day}": use "HH:MM-HH:MM" or "closed".'
                )
        return value

    def validate(self, attrs):
        # On partial update, moving the node needs both coordinates.
        if self.partial and ("latitude" in attrs) != ("longitude" in attrs):
            raise serializers.ValidationError(
                "latitude and longitude must be provided together."
            )
        return attrs

    def _set_location(self, node, lat, lng):
        if settings.USE_GIS:
            from django.contrib.gis.geos import Point

            node.location = Point(lng, lat, srid=4326)
        else:
            node.location = (lat, lng)

    def _replace_photos(self, node, photos):
        node.photos.all().delete()
        for order, image in enumerate(photos):
            NodePhoto.objects.create(node=node, image=image, order=order)

    def create(self, validated_data):
        photos = validated_data.pop("photos", [])
        lat = validated_data.pop("latitude")
        lng = validated_data.pop("longitude")
        user = self.context["request"].user
        with transaction.atomic():
            node = Node(manager=user, is_active=False, **validated_data)
            self._set_location(node, lat, lng)
            node.save()
            self._replace_photos(node, photos)
            # Registering a node makes you a Node Manager (§5, Phase 2).
            if user.role != User.Role.NODE_MANAGER:
                user.role = User.Role.NODE_MANAGER
                user.save(update_fields=["role"])
        return node

    def update(self, instance, validated_data):
        photos = validated_data.pop("photos", None)
        has_coords = "latitude" in validated_data
        lat = validated_data.pop("latitude", None)
        lng = validated_data.pop("longitude", None)
        with transaction.atomic():
            instance = super().update(instance, validated_data)
            if has_coords:
                self._set_location(instance, lat, lng)
                instance.save()
            if photos is not None:
                self._replace_photos(instance, photos)
        return instance
