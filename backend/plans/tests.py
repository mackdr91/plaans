from django.test import TestCase
from rest_framework.test import APIClient
from .mongo_repo import repo


class PlansApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.headers = {"HTTP_X_PLAANS_UID": "creator_test_1"}
        repo.delete_user_by_email("alex@plaans.app")
        repo.delete_test_plan("plan_test_tokyo", "tokyo-secret-weekend")
        repo.delete_test_plan("plan_email_auth", "alex-kyoto-guide")

    def test_health_and_plan_lifecycle_with_pin_protection(self):
        # 1. Health check
        health = self.client.get("/api/health/")
        self.assertEqual(health.status_code, 200)
        self.assertEqual(health.json()["status"], "ok")
        self.assertEqual(health.json()["authProviders"], ["email"])

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

    def test_email_password_auth(self):
        # 1. Register with Email & Password
        reg_res = self.client.post(
            "/api/auth/register/",
            data={
                "email": "alex@plaans.app",
                "password": "supersecretpassword",
                "displayName": "Alex Rivera",
            },
            format="json",
        )
        self.assertEqual(reg_res.status_code, 201)
        reg_body = reg_res.json()
        self.assertTrue(reg_body["token"].startswith("plaans_jwt."))
        self.assertEqual(reg_body["user"]["email"], "alex@plaans.app")
        self.assertEqual(reg_body["user"]["authProvider"], "email")
        self.assertNotIn("passwordHash", reg_body["user"])

        # 2. Duplicate registration should fail with 400
        dup_res = self.client.post(
            "/api/auth/register/",
            data={
                "email": "alex@plaans.app",
                "password": "anotherpassword",
            },
            format="json",
        )
        self.assertEqual(dup_res.status_code, 400)

        # 3. Wrong password login fails with 401
        bad_login = self.client.post(
            "/api/auth/login/",
            data={"email": "alex@plaans.app", "password": "wrongpassword"},
            format="json",
        )
        self.assertEqual(bad_login.status_code, 401)

        # 4. Valid Email/Password login returns token & user
        login_res = self.client.post(
            "/api/auth/login/",
            data={"email": "alex@plaans.app", "password": "supersecretpassword"},
            format="json",
        )
        self.assertEqual(login_res.status_code, 200)
        email_token = login_res.json()["token"]

        # 5. GET /api/auth/me/ with Bearer token works
        me_res = self.client.get(
            "/api/auth/me/",
            HTTP_AUTHORIZATION=f"Bearer {email_token}",
        )
        self.assertEqual(me_res.status_code, 200)
        self.assertEqual(me_res.json()["user"]["displayName"], "Alex Rivera")

        # 6. Authenticated plan save using Email/Password token
        plan_res = self.client.post(
            "/api/plans/",
            data={
                "id": "plan_email_auth",
                "slug": "alex-kyoto-guide",
                "title": "Alex's Kyoto Guide",
                "blocks": [],
            },
            format="json",
            HTTP_AUTHORIZATION=f"Bearer {email_token}",
        )
        self.assertEqual(plan_res.status_code, 200)
        self.assertEqual(
            plan_res.json()["plan"]["ownerEmail"],
            "alex@plaans.app",
        )
