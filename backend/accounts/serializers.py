from django.conf import settings
from django.contrib.auth.password_validation import validate_password

from rest_framework import serializers

from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Own-profile serializer for /auth/me/ and auth responses.

    Location is mode-agnostic (MASTER_PLAN §8.3): read as
    ``location: {"lat": ..., "lng": ...}``, written via ``latitude`` +
    ``longitude`` — the serializer maps onto either the PointField (USE_GIS
    on) or the plain float columns (off).
    """

    display_name = serializers.CharField(
        source="first_name", required=False, allow_blank=True, max_length=150
    )
    location = serializers.SerializerMethodField()
    latitude = serializers.FloatField(
        write_only=True, required=False, allow_null=True, min_value=-90, max_value=90
    )
    longitude = serializers.FloatField(
        write_only=True, required=False, allow_null=True, min_value=-180, max_value=180
    )

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "username",
            "display_name",
            "phone_number",
            "is_phone_verified",
            "photo",
            "role",
            "rating",
            "total_rentals",
            "total_lendings",
            "location",
            "latitude",
            "longitude",
            "address",
            "fcm_token",
            "is_id_verified",
            "date_joined",
        )
        # Never client-editable: identity, role, rating, counters, and
        # verification flags (spec item 5). phone_number changes only through
        # the verify-phone flow (§8.1).
        read_only_fields = (
            "id",
            "email",
            "username",
            "phone_number",
            "is_phone_verified",
            "role",
            "rating",
            "total_rentals",
            "total_lendings",
            "is_id_verified",
            "date_joined",
        )

    def get_location(self, obj):
        loc = obj.location
        if loc is None:
            return None
        if settings.USE_GIS:
            return {"lat": loc.y, "lng": loc.x}
        return {"lat": loc[0], "lng": loc[1]}

    def validate(self, attrs):
        has_lat = "latitude" in attrs
        has_lng = "longitude" in attrs
        if has_lat != has_lng:
            raise serializers.ValidationError(
                "latitude and longitude must be provided together."
            )
        if has_lat and (attrs["latitude"] is None) != (attrs["longitude"] is None):
            raise serializers.ValidationError(
                "latitude and longitude must both be set or both be null."
            )
        return attrs

    def update(self, instance, validated_data):
        has_coords = "latitude" in validated_data
        lat = validated_data.pop("latitude", None)
        lng = validated_data.pop("longitude", None)
        if has_coords:
            if lat is None:
                instance.location = None
            elif settings.USE_GIS:
                from django.contrib.gis.geos import Point

                instance.location = Point(lng, lat, srid=4326)
            else:
                instance.location = (lat, lng)
        return super().update(instance, validated_data)


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={"input_type": "password"})
    display_name = serializers.CharField(max_length=150)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        return User.objects.create_user(
            email=validated_data["email"],
            password=validated_data["password"],
            first_name=validated_data["display_name"],
        )


class VerifyPhoneSerializer(serializers.Serializer):
    id_token = serializers.CharField()
