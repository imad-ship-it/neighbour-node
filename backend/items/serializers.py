from django.conf import settings
from django.db import transaction

from rest_framework import serializers

from nodes.models import Node
# Generic public-user payload (id, display_name, photo, rating) — reused for
# item owners; defined in nodes because Phase 2 introduced it.
from nodes.serializers import ManagerPublicSerializer, location_dict

from .models import Item, ItemImage

MAX_IMAGES = 5


class ItemImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ItemImage
        fields = ("id", "image", "order")


class ItemListSerializer(serializers.ModelSerializer):
    """Compact item payload for /items/nearby/, /items/my/, and inventory."""

    location = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    thumbnail = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = (
            "id",
            "title",
            "category",
            "condition",
            "daily_rate",
            "deposit_amount",
            "storage_type",
            "listing_status",
            "is_available",
            "node",
            "location",
            "distance",
            "thumbnail",
            "created_at",
        )

    def get_location(self, obj) -> dict:
        return location_dict(obj)

    def get_distance(self, obj) -> float | None:
        """Meters from the query point; set by the nearby view."""
        distance = getattr(obj, "distance", None)
        return None if distance is None else round(distance, 1)

    def get_thumbnail(self, obj) -> str | None:
        image = next(iter(obj.images.all()), None)
        if image is None:
            return None
        url = image.image.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request else url


class ItemDetailSerializer(serializers.ModelSerializer):
    """Full item payload for detail views and create/review responses."""

    location = serializers.SerializerMethodField()
    images = ItemImageSerializer(many=True, read_only=True)
    owner = ManagerPublicSerializer(read_only=True)
    node_name = serializers.CharField(
        source="node.name", read_only=True, default=None
    )

    class Meta:
        model = Item
        fields = (
            "id",
            "title",
            "description",
            "category",
            "condition",
            "daily_rate",
            "deposit_amount",
            "storage_type",
            "listing_status",
            "is_available",
            "node",
            "node_name",
            "owner",
            "location",
            "images",
            "created_at",
        )

    def get_location(self, obj) -> dict:
        return location_dict(obj)


class ItemCreateSerializer(serializers.ModelSerializer):
    """Input for POST /items/.

    Donation flow (§4.3): `node` set → the item lands in the manager's queue
    as PENDING_DONATION; otherwise it's a personal item, ACTIVE immediately.
    Location is never client-supplied — it's copied from the node or owner.
    """

    node = serializers.PrimaryKeyRelatedField(
        queryset=Node.objects.all(), required=False, allow_null=True
    )
    storage_type = serializers.ChoiceField(
        choices=Item.StorageType.choices, required=False
    )
    images = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=False,
        max_length=MAX_IMAGES,
        error_messages={
            "max_length": f"An item can have at most {MAX_IMAGES} images."
        },
    )

    class Meta:
        model = Item
        fields = (
            "title",
            "description",
            "category",
            "condition",
            "daily_rate",
            "deposit_amount",
            "node",
            "storage_type",
            "images",
        )

    def validate(self, attrs):
        node = attrs.get("node")
        storage_type = attrs.get("storage_type")
        if storage_type == Item.StorageType.PERSONAL and node is not None:
            raise serializers.ValidationError(
                {"storage_type": "A PERSONAL item cannot have a node."}
            )
        if storage_type == Item.StorageType.NODE and node is None:
            raise serializers.ValidationError(
                {"storage_type": "A NODE item requires a node."}
            )
        if node is not None and not node.is_active:
            raise serializers.ValidationError(
                {"node": "This node is not approved yet."}
            )
        if node is None and self.context["request"].user.location is None:
            raise serializers.ValidationError(
                "Set your location first (PATCH /auth/me/) so neighbours can "
                "find your item."
            )
        return attrs

    def create(self, validated_data):
        images = validated_data.pop("images", [])
        validated_data.pop("storage_type", None)  # always derived below
        node = validated_data.get("node")
        owner = self.context["request"].user
        with transaction.atomic():
            item = Item(owner=owner, **validated_data)
            if node is not None:
                item.storage_type = Item.StorageType.NODE
                item.listing_status = Item.ListingStatus.PENDING_DONATION
                source = node
            else:
                item.storage_type = Item.StorageType.PERSONAL
                item.listing_status = Item.ListingStatus.ACTIVE
                source = owner
            if settings.USE_GIS:
                item.location = source.location
            else:
                item.location = (source.latitude, source.longitude)
            item.save()
            for order, image in enumerate(images):
                ItemImage.objects.create(item=item, image=image, order=order)
        return item


class ItemUpdateSerializer(serializers.ModelSerializer):
    """PATCH /items/{id}/ — listing_status, node, storage_type and location
    stay server-controlled after create."""

    images = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=False,
        max_length=MAX_IMAGES,
        error_messages={
            "max_length": f"An item can have at most {MAX_IMAGES} images."
        },
    )

    class Meta:
        model = Item
        fields = (
            "title",
            "description",
            "category",
            "condition",
            "daily_rate",
            "deposit_amount",
            "is_available",
            "images",
        )

    def update(self, instance, validated_data):
        images = validated_data.pop("images", None)
        with transaction.atomic():
            instance = super().update(instance, validated_data)
            if images is not None:
                instance.images.all().delete()
                for order, image in enumerate(images):
                    ItemImage.objects.create(
                        item=instance, image=image, order=order
                    )
        return instance


class ReviewDonationSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=("accept", "reject"))
