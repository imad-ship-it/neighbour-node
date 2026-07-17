from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class UserManagerTests(TestCase):
    def test_create_user(self):
        user = User.objects.create_user(email="user@example.com", password="s3cret-pass")
        self.assertEqual(user.email, "user@example.com")
        self.assertTrue(user.check_password("s3cret-pass"))
        self.assertEqual(user.username, "user@example.com")
        self.assertEqual(user.role, User.Role.USER)
        self.assertEqual(user.rating, Decimal("0.00"))
        self.assertEqual(user.total_rentals, 0)
        self.assertEqual(user.total_lendings, 0)
        self.assertFalse(user.is_phone_verified)
        self.assertFalse(user.is_id_verified)
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)
        self.assertIsNone(user.location)

    def test_create_user_requires_email(self):
        with self.assertRaises(ValueError):
            User.objects.create_user(email="", password="s3cret-pass")

    def test_create_user_normalizes_email_domain(self):
        user = User.objects.create_user(email="user@EXAMPLE.COM", password="s3cret-pass")
        self.assertEqual(user.email, "user@example.com")

    def test_create_superuser(self):
        admin = User.objects.create_superuser(
            email="admin@example.com", password="s3cret-pass"
        )
        self.assertTrue(admin.is_staff)
        self.assertTrue(admin.is_superuser)
        self.assertEqual(admin.email, "admin@example.com")

    def test_create_superuser_rejects_downgraded_flags(self):
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email="admin@example.com", password="s3cret-pass", is_staff=False
            )
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email="admin@example.com", password="s3cret-pass", is_superuser=False
            )


class UserModelTests(TestCase):
    def test_email_is_unique(self):
        User.objects.create_user(email="dupe@example.com", password="s3cret-pass")
        with self.assertRaises(IntegrityError):
            # Distinct username so the email column is what collides.
            User.objects.create_user(
                email="dupe@example.com", password="s3cret-pass", username="other"
            )

    def test_location_property_round_trip(self):
        user = User.objects.create_user(email="geo@example.com", password="s3cret-pass")
        user.location = (33.6844, 73.0479)  # Islamabad
        user.save()
        user.refresh_from_db()
        self.assertEqual(user.location, (33.6844, 73.0479))
        user.location = None
        self.assertIsNone(user.location)


REGISTER_URL = "/api/v1/auth/register/"
LOGIN_URL = "/api/v1/auth/login/"
ME_URL = "/api/v1/auth/me/"
VERIFY_PHONE_URL = "/api/v1/auth/verify-phone/"


class RegisterApiTests(APITestCase):
    payload = {
        "email": "new@example.com",
        "password": "Str0ng-pass-123",
        "display_name": "New User",
    }

    def test_register_happy_path(self):
        response = self.client.post(REGISTER_URL, self.payload)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["email"], "new@example.com")
        self.assertEqual(response.data["user"]["display_name"], "New User")
        self.assertNotIn("password", response.data["user"])
        user = User.objects.get(email="new@example.com")
        self.assertTrue(user.check_password("Str0ng-pass-123"))

    def test_register_duplicate_email(self):
        User.objects.create_user(email="new@example.com", password="s3cret-pass")
        response = self.client.post(REGISTER_URL, self.payload)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data)

    def test_register_rejects_weak_password(self):
        response = self.client.post(
            REGISTER_URL, {**self.payload, "password": "123"}
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data)


class LoginApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="login@example.com", password="Str0ng-pass-123"
        )

    def test_login_returns_token_pair(self):
        response = self.client.post(
            LOGIN_URL, {"email": "login@example.com", "password": "Str0ng-pass-123"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_login_wrong_password(self):
        response = self.client.post(
            LOGIN_URL, {"email": "login@example.com", "password": "wrong-pass"}
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class MeApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="me@example.com", password="Str0ng-pass-123", first_name="Me"
        )

    def test_me_requires_auth(self):
        response = self.client.get(ME_URL)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_returns_own_profile(self):
        self.client.force_authenticate(self.user)
        response = self.client.get(ME_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], "me@example.com")

    def test_me_patch_updates_location_and_fcm_token(self):
        self.client.force_authenticate(self.user)
        response = self.client.patch(
            ME_URL,
            {"latitude": 33.6844, "longitude": 73.0479, "fcm_token": "token-abc"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data["location"], {"lat": 33.6844, "lng": 73.0479}
        )
        self.user.refresh_from_db()
        self.assertEqual(self.user.location, (33.6844, 73.0479))
        self.assertEqual(self.user.fcm_token, "token-abc")

    def test_me_patch_cannot_change_role(self):
        self.client.force_authenticate(self.user)
        response = self.client.patch(
            ME_URL,
            {"role": "NODE_MANAGER", "rating": "5.00", "is_id_verified": True},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, User.Role.USER)
        self.assertEqual(self.user.rating, Decimal("0.00"))
        self.assertFalse(self.user.is_id_verified)


class VerifyPhoneApiTests(APITestCase):
    def test_verify_phone_is_stubbed(self):
        user = User.objects.create_user(
            email="phone@example.com", password="Str0ng-pass-123"
        )
        self.client.force_authenticate(user)
        response = self.client.post(VERIFY_PHONE_URL, {"id_token": "fake-token"})
        self.assertEqual(response.status_code, status.HTTP_501_NOT_IMPLEMENTED)
