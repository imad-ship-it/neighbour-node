import shutil
import tempfile
from decimal import Decimal

from django.test import override_settings
from rest_framework import status
from rest_framework.test import APITestCase

from nodes.tests import QUERY_LAT, QUERY_LNG, make_image, make_node, make_user

from .models import Item

ITEMS_URL = "/api/v1/items/"
NEARBY_URL = "/api/v1/items/nearby/"
MY_URL = "/api/v1/items/my/"

TEMP_MEDIA = tempfile.mkdtemp(prefix="items-test-media-")


def make_owner(email, lat=QUERY_LAT, lng=QUERY_LNG):
    """User with a saved location (personal items require one)."""
    user = make_user(email)
    user.location = (lat, lng)
    user.save()
    return user


def make_item(owner, lat=QUERY_LAT, lng=QUERY_LNG, node=None, **extra):
    item = Item(
        owner=owner,
        node=node,
        storage_type=(
            Item.StorageType.NODE if node else Item.StorageType.PERSONAL
        ),
        listing_status=extra.pop("listing_status", Item.ListingStatus.ACTIVE),
        title=extra.pop("title", "DeWalt Power Drill"),
        category=extra.pop("category", Item.Category.TOOLS),
        condition=extra.pop("condition", Item.Condition.GOOD),
        daily_rate=extra.pop("daily_rate", Decimal("500.00")),
        deposit_amount=extra.pop("deposit_amount", Decimal("2000.00")),
        **extra,
    )
    item.location = (lat, lng)
    item.save()
    return item


@override_settings(MEDIA_ROOT=TEMP_MEDIA)
class CreateItemApiTests(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(TEMP_MEDIA, ignore_errors=True)

    def setUp(self):
        self.owner = make_owner("owner@example.com")
        self.manager = make_user("manager@example.com")
        self.node = make_node(self.manager, 33.7176, 73.0505)
        self.client.force_authenticate(self.owner)

    def _payload(self, **overrides):
        payload = {
            "title": "DeWalt Power Drill",
            "description": "Barely used",
            "category": "TOOLS",
            "condition": "GOOD",
            "daily_rate": "500.00",
            "deposit_amount": "2000.00",
        }
        payload.update(overrides)
        return payload

    def test_personal_item_is_active_with_owner_location(self):
        response = self.client.post(
            ITEMS_URL,
            self._payload(images=[make_image("a.jpg")]),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["listing_status"], "ACTIVE")
        self.assertEqual(response.data["storage_type"], "PERSONAL")
        self.assertIsNone(response.data["node"])
        item = Item.objects.get(id=response.data["id"])
        self.assertEqual(item.location, (QUERY_LAT, QUERY_LNG))
        self.assertEqual(item.images.count(), 1)

    def test_personal_item_requires_owner_location(self):
        no_location = make_user("nowhere@example.com")
        self.client.force_authenticate(no_location)
        response = self.client.post(ITEMS_URL, self._payload(), format="multipart")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_node_item_becomes_pending_donation_at_node_location(self):
        response = self.client.post(
            ITEMS_URL, self._payload(node=self.node.id), format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["listing_status"], "PENDING_DONATION")
        self.assertEqual(response.data["storage_type"], "NODE")
        item = Item.objects.get(id=response.data["id"])
        self.assertEqual(item.location, self.node.location)

    def test_storage_type_node_mismatch_rejected(self):
        for overrides in (
            {"storage_type": "PERSONAL", "node": self.node.id},
            {"storage_type": "NODE"},
        ):
            response = self.client.post(
                ITEMS_URL, self._payload(**overrides), format="multipart"
            )
            self.assertEqual(
                response.status_code, status.HTTP_400_BAD_REQUEST, overrides
            )
            self.assertIn("storage_type", response.data)

    def test_zero_daily_rate_rejected(self):
        response = self.client.post(
            ITEMS_URL, self._payload(daily_rate="0.00"), format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("daily_rate", response.data)

    def test_donating_to_unapproved_node_rejected(self):
        pending_node = make_node(
            self.manager, QUERY_LAT, QUERY_LNG, name="Pending", is_active=False
        )
        response = self.client.post(
            ITEMS_URL, self._payload(node=pending_node.id), format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("node", response.data)

    def test_more_than_five_images_rejected(self):
        response = self.client.post(
            ITEMS_URL,
            self._payload(images=[make_image(f"{i}.jpg") for i in range(6)]),
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("images", response.data)


class DonationFlowTests(APITestCase):
    def setUp(self):
        self.owner = make_owner("donor@example.com")
        self.manager = make_user("manager@example.com")
        self.stranger = make_user("stranger@example.com")
        self.node = make_node(self.manager, 33.7176, 73.0505)
        self.item = make_item(
            self.owner,
            node=self.node,
            listing_status=Item.ListingStatus.PENDING_DONATION,
        )
        self.review_url = f"{ITEMS_URL}{self.item.id}/review-donation/"

    def test_manager_accepts_donation(self):
        self.client.force_authenticate(self.manager)
        response = self.client.post(self.review_url, {"action": "accept"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.item.refresh_from_db()
        self.assertEqual(self.item.listing_status, Item.ListingStatus.ACTIVE)
        # Accepted item now shows up in the node's inventory.
        inventory = self.client.get(f"/api/v1/nodes/{self.node.id}/inventory/")
        self.assertEqual([item["id"] for item in inventory.data], [self.item.id])

    def test_manager_rejects_donation(self):
        self.client.force_authenticate(self.manager)
        response = self.client.post(self.review_url, {"action": "reject"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.item.refresh_from_db()
        self.assertEqual(self.item.listing_status, Item.ListingStatus.REJECTED)

    def test_owner_and_stranger_cannot_review(self):
        for user in (self.owner, self.stranger):
            self.client.force_authenticate(user)
            response = self.client.post(self.review_url, {"action": "accept"})
            self.assertEqual(
                response.status_code, status.HTTP_403_FORBIDDEN, user.email
            )
        self.item.refresh_from_db()
        self.assertEqual(
            self.item.listing_status, Item.ListingStatus.PENDING_DONATION
        )

    def test_reviewing_non_pending_item_rejected(self):
        self.item.listing_status = Item.ListingStatus.ACTIVE
        self.item.save(update_fields=["listing_status"])
        self.client.force_authenticate(self.manager)
        response = self.client.post(self.review_url, {"action": "reject"})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_pending_donations_queue_is_manager_only(self):
        url = f"/api/v1/nodes/{self.node.id}/pending-donations/"
        self.client.force_authenticate(self.manager)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual([item["id"] for item in response.data], [self.item.id])
        # Detail payload: the review UI shows who is donating.
        self.assertEqual(response.data[0]["owner"]["id"], self.owner.id)

        self.client.force_authenticate(self.stranger)
        self.assertEqual(
            self.client.get(url).status_code, status.HTTP_403_FORBIDDEN
        )


class NearbyItemsApiTests(APITestCase):
    def setUp(self):
        self.seeker = make_user("seeker@example.com")
        self.owner = make_owner("owner@example.com")
        self.manager = make_user("manager@example.com")
        self.node = make_node(self.manager, 33.7176, 73.0505)
        self.client.force_authenticate(self.seeker)

        # ~110 m: an active tool.
        self.drill = make_item(self.owner, 33.7096, 73.0505)
        # ~1 km: an active cheap book.
        self.book = make_item(
            self.owner,
            33.7176,
            73.0505,
            title="Clean Code",
            category=Item.Category.BOOKS,
            daily_rate=Decimal("200.00"),
        )
        # Node item (accepted donation) at the node's location.
        self.node_item = make_item(self.owner, 33.7176, 73.0505, node=self.node)
        # Should never appear: far away / pending / unavailable.
        make_item(self.owner, 31.5497, 74.3436, title="Far item")
        make_item(
            self.owner,
            node=self.node,
            listing_status=Item.ListingStatus.PENDING_DONATION,
            title="Pending item",
        )
        make_item(self.owner, is_available=False, title="Rented out")

    def _get(self, **params):
        return self.client.get(
            NEARBY_URL, {"lat": QUERY_LAT, "lng": QUERY_LNG, **params}
        )

    def test_requires_lat_lng(self):
        response = self.client.get(NEARBY_URL)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_returns_active_available_items_nearest_first(self):
        response = self._get()
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        titles = [item["title"] for item in response.data]
        self.assertEqual(len(titles), 3)
        self.assertEqual(titles[0], "DeWalt Power Drill")
        self.assertNotIn("Far item", titles)
        self.assertNotIn("Pending item", titles)
        self.assertNotIn("Rented out", titles)
        distances = [item["distance"] for item in response.data]
        self.assertEqual(distances, sorted(distances))

    def test_radius_filter(self):
        response = self._get(radius=500)
        titles = [item["title"] for item in response.data]
        self.assertEqual(titles, ["DeWalt Power Drill"])

    def test_category_filter(self):
        response = self._get(category="BOOKS")
        titles = [item["title"] for item in response.data]
        self.assertEqual(titles, ["Clean Code"])

    def test_max_rate_filter(self):
        response = self._get(max_rate=300)
        titles = [item["title"] for item in response.data]
        self.assertEqual(titles, ["Clean Code"])

    def test_storage_type_filter(self):
        response = self._get(storage_type="NODE")
        ids = [item["id"] for item in response.data]
        self.assertEqual(ids, [self.node_item.id])


class MyItemsApiTests(APITestCase):
    def test_returns_only_own_items_including_pending(self):
        owner = make_owner("mine@example.com")
        other = make_owner("other@example.com")
        manager = make_user("manager@example.com")
        node = make_node(manager, 33.7176, 73.0505)
        mine_active = make_item(owner)
        mine_pending = make_item(
            owner, node=node, listing_status=Item.ListingStatus.PENDING_DONATION
        )
        make_item(other, title="Not mine")

        self.client.force_authenticate(owner)
        response = self.client.get(MY_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = {item["id"] for item in response.data}
        self.assertEqual(ids, {mine_active.id, mine_pending.id})


class ItemDetailApiTests(APITestCase):
    def setUp(self):
        self.owner = make_owner("owner@example.com")
        self.manager = make_user("manager@example.com")
        self.stranger = make_user("stranger@example.com")
        self.node = make_node(self.manager, 33.7176, 73.0505)
        self.personal = make_item(self.owner)
        self.node_item = make_item(self.owner, node=self.node)

    def _url(self, item):
        return f"{ITEMS_URL}{item.id}/"

    def test_owner_can_patch(self):
        self.client.force_authenticate(self.owner)
        response = self.client.patch(
            self._url(self.personal), {"daily_rate": "650.00"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.personal.refresh_from_db()
        self.assertEqual(self.personal.daily_rate, Decimal("650.00"))

    def test_node_manager_can_patch_node_item(self):
        self.client.force_authenticate(self.manager)
        response = self.client.patch(
            self._url(self.node_item), {"is_available": False}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.node_item.refresh_from_db()
        self.assertFalse(self.node_item.is_available)

    def test_manager_cannot_patch_personal_item(self):
        self.client.force_authenticate(self.manager)
        response = self.client.patch(
            self._url(self.personal), {"daily_rate": "1.00"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_stranger_cannot_patch_or_delete(self):
        self.client.force_authenticate(self.stranger)
        self.assertEqual(
            self.client.patch(
                self._url(self.personal), {"title": "hijack"}, format="json"
            ).status_code,
            status.HTTP_403_FORBIDDEN,
        )
        self.assertEqual(
            self.client.delete(self._url(self.personal)).status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_owner_can_delete(self):
        self.client.force_authenticate(self.owner)
        response = self.client.delete(self._url(self.personal))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Item.objects.filter(id=self.personal.id).exists())

    def test_listing_status_not_client_writable(self):
        pending = make_item(
            self.owner,
            node=self.node,
            listing_status=Item.ListingStatus.PENDING_DONATION,
        )
        self.client.force_authenticate(self.owner)
        response = self.client.patch(
            self._url(pending), {"listing_status": "ACTIVE"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        pending.refresh_from_db()
        self.assertEqual(
            pending.listing_status, Item.ListingStatus.PENDING_DONATION
        )


class ItemDetailReadTests(APITestCase):
    def test_detail_includes_images_owner_and_node_name(self):
        owner = make_owner("owner@example.com")
        manager = make_user("manager@example.com")
        node = make_node(manager, 33.7176, 73.0505)
        item = make_item(owner, node=node)
        self.client.force_authenticate(make_user("viewer@example.com"))
        response = self.client.get(f"{ITEMS_URL}{item.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["node_name"], node.name)
        self.assertEqual(response.data["owner"]["id"], owner.id)
        self.assertEqual(response.data["images"], [])
