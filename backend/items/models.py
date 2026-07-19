from decimal import Decimal

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models

if settings.USE_GIS:
    from django.contrib.gis.db import models as gis_models


class Item(models.Model):
    """A rentable (or donated) item — MASTER_PLAN §4.3."""

    class StorageType(models.TextChoices):
        PERSONAL = "PERSONAL", "Personal"
        NODE = "NODE", "Node"

    class ListingStatus(models.TextChoices):
        PENDING_DONATION = "PENDING_DONATION", "Pending donation"
        ACTIVE = "ACTIVE", "Active"
        REJECTED = "REJECTED", "Rejected"
        ARCHIVED = "ARCHIVED", "Archived"

    class Category(models.TextChoices):
        TOOLS = "TOOLS", "Tools"
        BOOKS = "BOOKS", "Books"
        ELECTRONICS = "ELECTRONICS", "Electronics"
        SPORTS = "SPORTS", "Sports"
        OTHER = "OTHER", "Other"

    class Condition(models.TextChoices):
        NEW = "NEW", "New"
        GOOD = "GOOD", "Good"
        FAIR = "FAIR", "Fair"
        POOR = "POOR", "Poor"

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="items",
        help_text="Original owner, even when donated",
    )
    node = models.ForeignKey(
        "nodes.Node",
        on_delete=models.CASCADE,
        related_name="items",
        null=True,
        blank=True,
        help_text="Null = personal P2P item",
    )
    storage_type = models.CharField(max_length=10, choices=StorageType.choices)
    listing_status = models.CharField(
        max_length=20,
        choices=ListingStatus.choices,
        default=ListingStatus.ACTIVE,
    )
    title = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=15, choices=Category.choices)
    condition = models.CharField(max_length=5, choices=Condition.choices)
    daily_rate = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
        help_text="PKR per day",
    )
    deposit_amount = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0.01"))],
        help_text="Security deposit, PKR",
    )
    is_available = models.BooleanField(
        default=True, help_text="Toggled automatically by the transaction flow"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Location — copied on create from node.location (node items) or
    # owner.location (personal). Same USE_GIS dual-mode pattern as nodes.
    if settings.USE_GIS:
        location = gis_models.PointField(geography=True)
    else:
        latitude = models.FloatField()
        longitude = models.FloatField()

        @property
        def location(self):
            """(lat, lng) tuple."""
            if self.latitude is None or self.longitude is None:
                return None
            return (self.latitude, self.longitude)

        @location.setter
        def location(self, value):
            if value is None:
                self.latitude = None
                self.longitude = None
            else:
                self.latitude, self.longitude = value

    class Meta:
        ordering = ("-created_at",)

    def __str__(self):
        return self.title


class ItemImage(models.Model):
    """Up to 5 images per Item (§4.3); the cap is enforced in the serializer."""

    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="images")
    image = models.ImageField(upload_to="items/images/")
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ("order", "id")

    def __str__(self):
        return f"{self.item} image #{self.order}"
