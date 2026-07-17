import io
import json
import shutil
import tempfile
from datetime import datetime
from unittest import mock

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Node, NodePhoto

User = get_user_model()

NODES_URL = "/api/v1/nodes/"
NEARBY_URL = "/api/v1/nodes/nearby/"

TEMP_MEDIA = tempfile.mkdtemp(prefix="nodes-test-media-")

# Query point: F-7, Islamabad.
QUERY_LAT, QUERY_LNG = 33.7086, 73.0505

OPEN_ALL_WEEK = {
    "mon": "09:00-18:00",
    "tue": "09:00-18:00",
    "wed": "09:00-18:00",
    "thu": "09:00-18:00",
    "fri": "09:00-18:00",
    "sat": "10:00-16:00",
    "sun": "closed",
}


def make_user(email, **extra):
    return User.objects.create_user(email=email, password="Str0ng-pass-123", **extra)


def make_node(manager, lat, lng, name="Block C Storeroom", is_active=True, **extra):
    node = Node(
        manager=manager,
        name=name,
        address="Block C, F-7, Islamabad",
        capacity=20,
        is_active=is_active,
        operating_hours=extra.pop("operating_hours", OPEN_ALL_WEEK),
        **extra,
    )
    node.location = (lat, lng)
    node.save()
    return node


def make_image(name="photo.jpg"):
    buf = io.BytesIO()
    Image.new("RGB", (1, 1), "white").save(buf, format="JPEG")
    return SimpleUploadedFile(name, buf.getvalue(), content_type="image/jpeg")


class IsOpenNowTests(TestCase):
    def setUp(self):
        self.node = make_node(make_user("hours@example.com"), QUERY_LAT, QUERY_LNG)

    def _now(self, hour, minute=0):
        # 2026-07-15 is a Wednesday -> key "wed".
        return datetime(2026, 7, 15, hour, minute)

    def _is_open(self, hours, now):
        self.node.operating_hours = {**OPEN_ALL_WEEK, "wed": hours}
        with mock.patch("nodes.models.timezone.localtime", return_value=now):
            return self.node.is_open_now()

    def test_open_within_window(self):
        self.assertTrue(self._is_open("09:00-18:00", self._now(12)))

    def test_closed_outside_window(self):
        self.assertFalse(self._is_open("09:00-18:00", self._now(20)))

    def test_closed_day(self):
        self.assertFalse(self._is_open("closed", self._now(12)))

    def test_overnight_window(self):
        self.assertTrue(self._is_open("22:00-06:00", self._now(23)))
        self.assertTrue(self._is_open("22:00-06:00", self._now(5)))
        self.assertFalse(self._is_open("22:00-06:00", self._now(12)))

    def test_unparseable_counts_as_closed(self):
        self.assertFalse(self._is_open("9am-6pm", self._now(12)))


class NearbyApiTests(APITestCase):
    def setUp(self):
        self.user = make_user("seeker@example.com")
        self.manager = make_user("manager@example.com")
        self.client.force_authenticate(self.user)
        # ~1.0 km north of the query point.
        self.near = make_node(self.manager, 33.7176, 73.0505, name="Near Node")
        # ~110 m north — nearest.
        self.nearest = make_node(self.manager, 33.7096, 73.0505, name="Nearest Node")
        # Lahore, ~270 km away — outside any sane radius.
        self.far = make_node(self.manager, 31.5497, 74.3436, name="Far Node")
        # In range but not yet approved.
        self.inactive = make_node(
            self.manager, 33.7086, 73.0510, name="Pending Node", is_active=False
        )

    def _get(self, **params):
        return self.client.get(
            NEARBY_URL, {"lat": QUERY_LAT, "lng": QUERY_LNG, **params}
        )

    def test_requires_auth(self):
        self.client.force_authenticate(None)
        self.assertEqual(self._get().status_code, status.HTTP_401_UNAUTHORIZED)

    def test_requires_lat_lng(self):
        response = self.client.get(NEARBY_URL)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_returns_only_active_nodes_within_radius_nearest_first(self):
        response = self._get()
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [node["name"] for node in response.data]
        self.assertEqual(names, ["Nearest Node", "Near Node"])

    def test_distance_is_plausible(self):
        response = self._get()
        nearest, near = response.data
        self.assertAlmostEqual(nearest["distance"], 111, delta=30)
        self.assertAlmostEqual(near["distance"], 1000, delta=100)
        self.assertLess(nearest["distance"], near["distance"])

    def test_radius_excludes_nodes_beyond_it(self):
        response = self._get(radius=500)
        names = [node["name"] for node in response.data]
        self.assertEqual(names, ["Nearest Node"])

    def test_payload_shape(self):
        node = self._get().data[0]
        self.assertEqual(
            set(node.keys()),
            {
                "id",
                "name",
                "address",
                "location",
                "rating",
                "distance",
                "thumbnail",
                "is_open_now",
            },
        )
        self.assertEqual(node["location"], {"lat": 33.7096, "lng": 73.0505})
        self.assertIsNone(node["thumbnail"])
        self.assertIsInstance(node["is_open_now"], bool)


@override_settings(MEDIA_ROOT=TEMP_MEDIA)
class CreateNodeApiTests(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(TEMP_MEDIA, ignore_errors=True)

    def setUp(self):
        self.user = make_user("creator@example.com")
        self.client.force_authenticate(self.user)

    def _payload(self, **overrides):
        payload = {
            "name": "Block C Storeroom",
            "description": "Community storeroom",
            "address": "Block C, F-7, Islamabad",
            "latitude": QUERY_LAT,
            "longitude": QUERY_LNG,
            "operating_hours": json.dumps(OPEN_ALL_WEEK),
            "capacity": 25,
        }
        payload.update(overrides)
        return payload

    def test_create_requires_auth(self):
        self.client.force_authenticate(None)
        response = self.client.post(NODES_URL, self._payload(), format="multipart")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_create_inactive_node_and_promotes_creator(self):
        response = self.client.post(
            NODES_URL,
            self._payload(photos=[make_image("a.jpg"), make_image("b.jpg")]),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertFalse(response.data["is_active"])
        self.assertEqual(response.data["manager"]["id"], self.user.id)
        self.assertEqual(len(response.data["photos"]), 2)

        node = Node.objects.get(id=response.data["id"])
        self.assertFalse(node.is_active)
        self.assertEqual(node.manager, self.user)
        self.assertEqual(node.location, (QUERY_LAT, QUERY_LNG))
        self.assertEqual(list(node.photos.values_list("order", flat=True)), [0, 1])
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, User.Role.NODE_MANAGER)

    def test_create_rejects_more_than_three_photos(self):
        response = self.client.post(
            NODES_URL,
            self._payload(photos=[make_image(f"{i}.jpg") for i in range(4)]),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("photos", response.data)
        self.assertEqual(NodePhoto.objects.count(), 0)

    def test_create_rejects_missing_day(self):
        hours = {k: v for k, v in OPEN_ALL_WEEK.items() if k != "sun"}
        response = self.client.post(
            NODES_URL,
            self._payload(operating_hours=json.dumps(hours)),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("operating_hours", response.data)

    def test_create_rejects_bad_time_format(self):
        hours = {**OPEN_ALL_WEEK, "mon": "9am-6pm"}
        response = self.client.post(
            NODES_URL,
            self._payload(operating_hours=json.dumps(hours)),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("operating_hours", response.data)

    def test_create_new_node_keeps_existing_manager_role(self):
        self.user.role = User.Role.NODE_MANAGER
        self.user.save(update_fields=["role"])
        response = self.client.post(NODES_URL, self._payload(), format="multipart")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, User.Role.NODE_MANAGER)


class NodeDetailApiTests(APITestCase):
    def setUp(self):
        self.manager = make_user("owner@example.com", first_name="Owner")
        self.other = make_user("other@example.com")
        self.node = make_node(self.manager, QUERY_LAT, QUERY_LNG)
        self.url = f"{NODES_URL}{self.node.id}/"

    def test_retrieve(self):
        self.client.force_authenticate(self.other)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Block C Storeroom")
        self.assertEqual(response.data["operating_hours"], OPEN_ALL_WEEK)
        self.assertEqual(response.data["manager"]["display_name"], "Owner")
        self.assertEqual(
            response.data["location"], {"lat": QUERY_LAT, "lng": QUERY_LNG}
        )

    def test_patch_by_manager(self):
        self.client.force_authenticate(self.manager)
        response = self.client.patch(
            self.url,
            {
                "description": "Now with shelving",
                "operating_hours": {**OPEN_ALL_WEEK, "sun": "10:00-14:00"},
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.node.refresh_from_db()
        self.assertEqual(self.node.description, "Now with shelving")
        self.assertEqual(self.node.operating_hours["sun"], "10:00-14:00")

    def test_patch_forbidden_for_non_manager(self):
        self.client.force_authenticate(self.other)
        response = self.client.patch(
            self.url, {"description": "hijacked"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.node.refresh_from_db()
        self.assertNotEqual(self.node.description, "hijacked")

    def test_put_not_allowed(self):
        self.client.force_authenticate(self.manager)
        response = self.client.put(self.url, {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_inventory_stub_returns_empty_list(self):
        self.client.force_authenticate(self.other)
        response = self.client.get(f"{self.url}inventory/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, [])
