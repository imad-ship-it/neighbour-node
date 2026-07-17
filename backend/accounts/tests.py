from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.test import TestCase

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
