import copy
import hashlib
import logging
import secrets
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password

logger = logging.getLogger(__name__)


def _hash_pin(pin_code: str) -> str:
    return hashlib.sha256(f"plaans_pin:{pin_code.strip()}".encode("utf-8")).hexdigest()


class PlansMongoRepository:
    """
    MongoDB repository for storing and querying `PlanModel` itinerary documents
    and Creator user accounts (`users` collection).
    Automatically connects to MongoDB (`settings.MONGODB_URI`), and gracefully
    falls back to an in-memory document collection if MongoDB is unreachable
    (e.g., during unit tests or offline local development).
    """

    def __init__(self) -> None:
        self._mongo_client = None
        self._collection = None
        self._users_collection = None
        self._using_memory_fallback = False
        self._memory_docs: Dict[str, Dict[str, Any]] = {}
        self._memory_users: Dict[str, Dict[str, Any]] = {}
        self._init_connection()

    def _init_connection(self) -> None:
        uri = getattr(settings, "MONGODB_URI", "mongodb://localhost:27017")
        db_name = getattr(settings, "MONGODB_DB_NAME", "plaans_db")
        try:
            from pymongo import ASCENDING, MongoClient

            client = MongoClient(uri, serverSelectionTimeoutMS=1200)
            client.admin.command("ping")
            db = client[db_name]
            col = db["plans"]
            col.create_index([("slug", ASCENDING)], unique=True)
            col.create_index([("ownerUid", ASCENDING)])
            col.create_index([("id", ASCENDING)], unique=True)

            users_col = db["users"]
            users_col.create_index([("uid", ASCENDING)], unique=True)
            users_col.create_index([("email", ASCENDING)], unique=True)

            self._mongo_client = client
            self._collection = col
            self._users_collection = users_col
            self._using_memory_fallback = False
        except Exception as exc:
            logger.info(
                "MongoDB at %s not reachable (%s); using in-memory document store.",
                uri,
                exc,
            )
            self._using_memory_fallback = True

    @property
    def storage_engine(self) -> str:
        return "memory-fallback" if self._using_memory_fallback else "mongodb"

    # ── User Authentication & Account Persistence ────────────────────────────

    def create_email_user(
        self,
        email: str,
        password: str,
        display_name: Optional[str] = None,
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        normalized_email = email.strip().lower()
        if not normalized_email or "@" not in normalized_email:
            return None, "Please enter a valid email address."
        if len(password) < 6:
            return None, "Password must be at least 6 characters."

        existing = self._find_user_by_email(normalized_email)
        if existing:
            return None, "An account with this email already exists. Please sign in."

        now_iso = datetime.now(timezone.utc).isoformat()
        uid = f"usr_{secrets.token_hex(8)}"
        resolved_name = (
            display_name.strip()
            if display_name and display_name.strip()
            else normalized_email.split("@")[0]
        )

        user_doc: Dict[str, Any] = {
            "uid": uid,
            "email": normalized_email,
            "displayName": resolved_name,
            "photoUrl": None,
            "authProvider": "email",
            "passwordHash": make_password(password),
            "createdAt": now_iso,
            "lastLoginAt": now_iso,
        }

        self._save_user_doc(user_doc)
        return self._sanitize_user_for_response(user_doc), None

    def authenticate_email_user(
        self,
        email: str,
        password: str,
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        normalized_email = email.strip().lower()
        if not normalized_email or not password:
            return None, "Email and password are required."

        user_doc = self._find_user_by_email(normalized_email)
        if not user_doc:
            return None, "Invalid email or password."

        password_hash = user_doc.get("passwordHash")
        if not password_hash or not check_password(password, password_hash):
            return None, "Invalid email or password."

        user_doc["lastLoginAt"] = datetime.now(timezone.utc).isoformat()
        self._save_user_doc(user_doc)
        return self._sanitize_user_for_response(user_doc), None

    def get_user_by_uid(self, uid: str) -> Optional[Dict[str, Any]]:
        if not uid:
            return None
        if self._using_memory_fallback:
            doc = self._memory_users.get(uid)
            return self._sanitize_user_for_response(doc) if doc else None
        doc = self._users_collection.find_one({"uid": uid})
        return self._sanitize_user_for_response(dict(doc)) if doc else None

    def delete_user_by_email(self, email: str) -> None:
        normalized = email.strip().lower()
        if self._using_memory_fallback:
            to_remove = [
                uid
                for uid, doc in self._memory_users.items()
                if doc.get("email") == normalized
            ]
            for uid in to_remove:
                self._memory_users.pop(uid, None)
            return
        self._users_collection.delete_many({"email": normalized})

    def _find_user_by_email(self, normalized_email: str) -> Optional[Dict[str, Any]]:
        if self._using_memory_fallback:
            for doc in self._memory_users.values():
                if doc.get("email") == normalized_email:
                    return copy.deepcopy(doc)
            return None
        doc = self._users_collection.find_one({"email": normalized_email})
        return dict(doc) if doc else None

    def _save_user_doc(self, user_doc: Dict[str, Any]) -> None:
        uid = user_doc["uid"]
        cleaned = copy.deepcopy(user_doc)
        cleaned.pop("_id", None)
        if self._using_memory_fallback:
            self._memory_users[uid] = cleaned
        else:
            self._users_collection.replace_one({"uid": uid}, cleaned, upsert=True)

    @staticmethod
    def _sanitize_user_for_response(doc: Dict[str, Any]) -> Dict[str, Any]:
        cleaned = copy.deepcopy(doc)
        cleaned.pop("_id", None)
        cleaned.pop("passwordHash", None)
        return cleaned

    def is_slug_available(self, slug: str, exclude_plan_id: Optional[str] = None) -> bool:
        normalized = slug.strip().lower()
        if not normalized:
            return False
        if self._using_memory_fallback:
            for doc in self._memory_docs.values():
                if doc.get("slug") == normalized and doc.get("id") != exclude_plan_id:
                    return False
            return True

        query: Dict[str, Any] = {"slug": normalized}
        if exclude_plan_id:
            query["id"] = {"$ne": exclude_plan_id}
        return self._collection.count_documents(query, limit=1) == 0

    def upsert_plan(
        self,
        plan_data: Dict[str, Any],
        owner_uid: str,
        owner_email: Optional[str] = None,
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        plan_id = str(plan_data.get("id", "")).strip()
        slug = str(plan_data.get("slug", "")).strip().lower()
        if not plan_id or not slug:
            return None, "Both 'id' and 'slug' are required."

        # Check if another user/plan already owns this slug
        existing_by_slug = self._find_raw_by_slug(slug)
        if existing_by_slug and existing_by_slug.get("id") != plan_id:
            return None, f"Slug '{slug}' is already taken by another plan."

        existing_by_id = self._find_raw_by_id(plan_id)
        if (
            existing_by_id
            and existing_by_id.get("ownerUid")
            and existing_by_id.get("ownerUid") != owner_uid
        ):
            return None, "You do not have permission to overwrite this plan."

        doc = copy.deepcopy(plan_data)
        doc["id"] = plan_id
        doc["slug"] = slug
        doc["ownerUid"] = owner_uid
        if owner_email:
            doc["ownerEmail"] = owner_email
        doc["visibility"] = doc.get("visibility") or "public"
        doc["isCloudSynced"] = True
        doc["updatedAt"] = datetime.now(timezone.utc).isoformat()
        doc["viewCount"] = int(
            existing_by_id.get("viewCount", doc.get("viewCount", 0))
            if existing_by_id
            else doc.get("viewCount", 0)
        )

        # Store PIN hash if visibility == pinProtected
        raw_pin = str(doc.pop("pinCode", "") or "").strip()
        if doc["visibility"] == "pinProtected":
            if raw_pin:
                doc["pinHash"] = _hash_pin(raw_pin)
            elif existing_by_id and existing_by_id.get("pinHash"):
                doc["pinHash"] = existing_by_id["pinHash"]
        else:
            doc.pop("pinHash", None)

        if self._using_memory_fallback:
            self._memory_docs[plan_id] = doc
        else:
            self._collection.replace_one({"id": plan_id}, doc, upsert=True)

        return self._sanitize_for_response(doc), None

    def list_plans_for_owner(self, owner_uid: str) -> List[Dict[str, Any]]:
        if self._using_memory_fallback:
            docs = [
                self._sanitize_for_response(d)
                for d in self._memory_docs.values()
                if d.get("ownerUid") == owner_uid
            ]
            docs.sort(key=lambda x: x.get("updatedAt", ""), reverse=True)
            return docs

        cursor = self._collection.find({"ownerUid": owner_uid}).sort("updatedAt", -1)
        return [self._sanitize_for_response(d) for d in cursor]

    def get_plan_by_slug(
        self, slug: str, increment_views: bool = True
    ) -> Optional[Dict[str, Any]]:
        normalized = slug.strip().lower()
        doc = self._find_raw_by_slug(normalized)
        if not doc:
            return None
        if increment_views:
            self._increment_view_count(doc["id"])
            doc["viewCount"] = int(doc.get("viewCount", 0)) + 1
        return doc

    def verify_plan_pin(self, doc: Dict[str, Any], pin_code: str) -> bool:
        expected_hash = doc.get("pinHash")
        if not expected_hash:
            return True
        return _hash_pin(pin_code) == expected_hash

    def delete_plan(self, plan_id: str, owner_uid: str) -> bool:
        existing = self._find_raw_by_id(plan_id)
        if not existing or existing.get("ownerUid") != owner_uid:
            return False
        if self._using_memory_fallback:
            self._memory_docs.pop(plan_id, None)
            return True
        res = self._collection.delete_one({"id": plan_id, "ownerUid": owner_uid})
        return res.deleted_count > 0

    def _find_raw_by_slug(self, slug: str) -> Optional[Dict[str, Any]]:
        if self._using_memory_fallback:
            for d in self._memory_docs.values():
                if d.get("slug") == slug:
                    return copy.deepcopy(d)
            return None
        doc = self._collection.find_one({"slug": slug})
        return dict(doc) if doc else None

    def _find_raw_by_id(self, plan_id: str) -> Optional[Dict[str, Any]]:
        if self._using_memory_fallback:
            d = self._memory_docs.get(plan_id)
            return copy.deepcopy(d) if d else None
        doc = self._collection.find_one({"id": plan_id})
        return dict(doc) if doc else None

    def _increment_view_count(self, plan_id: str) -> None:
        if self._using_memory_fallback:
            if plan_id in self._memory_docs:
                self._memory_docs[plan_id]["viewCount"] = (
                    int(self._memory_docs[plan_id].get("viewCount", 0)) + 1
                )
            return
        self._collection.update_one({"id": plan_id}, {"$inc": {"viewCount": 1}})

    @staticmethod
    def _sanitize_for_response(doc: Dict[str, Any]) -> Dict[str, Any]:
        cleaned = copy.deepcopy(doc)
        cleaned.pop("_id", None)
        has_pin = bool(cleaned.pop("pinHash", None))
        cleaned["hasPin"] = has_pin
        return cleaned


repo = PlansMongoRepository()
