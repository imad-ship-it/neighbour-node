from decimal import Decimal

from django.conf import settings
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

if settings.USE_GIS:
    from django.contrib.gis.db import models as gis_models


class UserManager(BaseUserManager):
    """Email is the login identifier (MASTER_PLAN §4.1)."""

    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError("The email address must be set")
        email = self.normalize_email(email)
        # username is inherited from AbstractUser and stays unique; default it
        # to the email so callers only ever need the login identifier.
        extra_fields.setdefault("username", email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    """Custom user — MASTER_PLAN §4.1."""

    class Role(models.TextChoices):
        USER = "USER", "User"
        NODE_MANAGER = "NODE_MANAGER", "Node Manager"

    email = models.EmailField("email address", unique=True)
    phone_number = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        help_text="With country code, e.g. +92300...",
    )
    is_phone_verified = models.BooleanField(default=False)
    photo = models.ImageField(upload_to="users/photos/", null=True, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.USER)
    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal("0.00"),
        validators=[MinValueValidator(0), MaxValueValidator(5)],
        help_text="Running average 0.00-5.00",
    )
    total_rentals = models.PositiveIntegerField(default=0)
    total_lendings = models.PositiveIntegerField(default=0)
    address = models.CharField(max_length=255, blank=True)
    fcm_token = models.CharField(max_length=255, null=True, blank=True)
    is_id_verified = models.BooleanField(default=False)

    # Location — MASTER_PLAN §8.3 fallback. With USE_GIS on this is a PostGIS
    # PointField; with it off, two plain floats behind a `location` property so
    # calling code reads/writes user.location either way. Flipping USE_GIS
    # requires a follow-up migration (lat/lng <-> PointField).
    if settings.USE_GIS:
        location = gis_models.PointField(null=True, blank=True)
    else:
        latitude = models.FloatField(null=True, blank=True)
        longitude = models.FloatField(null=True, blank=True)

        @property
        def location(self):
            """(lat, lng) tuple, or None when unset."""
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

    USERNAME_FIELD = "email"
    # Nothing besides email + password; the manager derives username.
    REQUIRED_FIELDS = []

    objects = UserManager()

    def __str__(self):
        return self.email
