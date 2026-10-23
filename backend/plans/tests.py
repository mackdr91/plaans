from django.test import TestCase
from rest_framework.test import APIClient


class PlansApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.headers = {"HTTP_X_PLAANS_UID": "creator_test_1"}

    def test_health_and_plan_lifecycle_with_pin_protection(self):
        # 1. Health check
        health = self.client.get("/api/health/")
        self.assertEqual(health.status_code, 200)
        self.assertEqual(health.json()["status"], "ok")

        # 2. Upsert a PIN-protected plan
        payload = {
            "id": "plan_test_tokyo",
            "slug": "tokyo-secret-weekend",
            "title": "Tokyo Secret Weekend",
            "subtitle": "Private group trip",
            "authorName": "Maya Lin",
            "visibility": "pinProtected",
            "pinCode": "4242",
            "blocks": [],
        }
        res = self.client.post(
            "/api/plans/",
            data=payload,
            format="json",
            **self.headers,
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["plan"]["hasPin"])

        # 3. Slug availability check should report false for another plan
        slug_check = self.client.get("/api/plans/check-slug/tokyo-secret-weekend/")
        self.assertFalse(slug_check.json()["available"])

        # 4. Anonymous visitor fetching by slug gets requiresPin=True
        visitor_res = self.client.get("/api/plans/by-slug/tokyo-secret-weekend/")
        self.assertEqual(visitor_res.status_code, 200)
        self.assertTrue(visitor_res.json()["requiresPin"])

        # 5. Unlocking with wrong PIN fails with 403
        bad_unlock = self.client.post(
            "/api/plans/by-slug/tokyo-secret-weekend/unlock/",
            data={"pinCode": "0000"},
            format="json",
        )
        self.assertEqual(bad_unlock.status_code, 403)

        # 6. Unlocking with right PIN returns full plan
        good_unlock = self.client.post(
            "/api/plans/by-slug/tokyo-secret-weekend/unlock/",
            data={"pinCode": "4242"},
            format="json",
        )
        self.assertEqual(good_unlock.status_code, 200)
        self.assertFalse(good_unlock.json()["requiresPin"])
        self.assertEqual(good_unlock.json()["plan"]["title"], "Tokyo Secret Weekend")
