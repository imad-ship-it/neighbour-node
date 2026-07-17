from datetime import datetime
from decimal import Decimal

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone

if settings.USE_GIS:
    from django.contrib.gis.db import models as gis_models

# Keys of the operating_hours JSON, indexed by datetime.weekday().
DAY_KEYS = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")


class Node(models.Model):
    """Community storeroom run by a Node Manager — MASTER_PLAN §4.2."""

    manager = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="managed_nodes",
    )
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    address = models.CharField(max_length=255, help_text="Public display address")
    operating_hours = models.JSONField(
        default=dict,
        help_text='{"mon": "09:00-18:00", ..., "sun": "closed"}',
    )
    capacity = models.PositiveIntegerField(help_text="Max items the room holds")
    is_active = models.BooleanField(
        default=False, help_text="Approved by admin via Django Admin"
    )
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(0), MaxValueValidator(5)],
        help_text="Avg of node ratings 0.00-5.00",
    )
    total_transactions = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Location — same USE_GIS dual-mode pattern as accounts.User (§8.3).
    # Required either way: a Node is a physical storeroom.
    if settings.USE_GIS:
        # geography=True so dwithin/Distance take meters, not degrees.
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
        return self.name

    def is_open_now(self):
        """Whether the current local time falls in today's operating window.

        Today's value is either "closed" or "HH:MM-HH:MM"; an end before the
        start means the window crosses midnight (e.g. "22:00-06:00").
        Missing/unparseable entries count as closed.
        """
        now = timezone.localtime()
        value = (self.operating_hours or {}).get(DAY_KEYS[now.weekday()])
        if not isinstance(value, str):
            return False
        value = value.strip().lower()
        if value == "closed":
            return False
        try:
            start_s, _, end_s = value.partition("-")
            start = datetime.strptime(start_s.strip(), "%H:%M").time()
            end = datetime.strptime(end_s.strip(), "%H:%M").time()
        except ValueError:
            return False
        current = now.time()
        if start == end:
            return False
        if end < start:  # overnight window
            return current >= start or current < end
        return start <= current < end


class NodePhoto(models.Model):
    """Up to 3 photos per Node (§4.2); the cap is enforced in the serializer."""

    node = models.ForeignKey(Node, on_delete=models.CASCADE, related_name="photos")
    image = models.ImageField(upload_to="nodes/photos/")
    order = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ("order", "id")

    def __str__(self):
        return f"{self.node} photo #{self.order}"
