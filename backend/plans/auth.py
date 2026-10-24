import logging
from dataclasses import dataclass
from typing import Any, Dict, Optional
from django.conf import settings
from django.core import signing

logger = logging.getLogger(__name__)

_firebase_initialized = False
_SESSION_SALT = "plaans.auth.session.v1"
_SESSION_MAX_AGE_SECONDS = 60 * 60 * 24 * 7  # 7 days


def _ensure_firebase_initialized() -> bool:
    global _firebase_initialized
    if _firebase_initialized:
        return True
    cred_path = getattr(settings, "FIREBASE_CREDENTIALS_JSON", "")
    if not cred_path:
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        return True
    except Exception as exc:
        logger.warning("Firebase Admin init skipped/failed: %s", exc)
        return False


@dataclass
class VerifiedCreator:
    uid: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    auth_provider: str = "email"
    is_firebase_verified: bool = False


def issue_session_token(user_doc: Dict[str, Any]) -> str:
    """Issues a cryptographically signed session token for an authenticated Creator."""
    payload = {
        "uid": user_doc["uid"],
        "email": user_doc.get("email"),
        "displayName": user_doc.get("displayName"),
        "authProvider": user_doc.get("authProvider", "email"),
    }
    return f"plaans_jwt.{signing.dumps(payload, salt=_SESSION_SALT)}"


def verify_session_token(token: str) -> Optional[VerifiedCreator]:
    """Verifies a `plaans_jwt.<signed>` token issued by `/api/auth/*`."""
    if not token.startswith("plaans_jwt."):
        return None
    raw_signed = token[len("plaans_jwt.") :]
    try:
        payload = signing.loads(
            raw_signed,
            salt=_SESSION_SALT,
            max_age=_SESSION_MAX_AGE_SECONDS,
        )
        return VerifiedCreator(
            uid=str(payload["uid"]),
            email=payload.get("email"),
            display_name=payload.get("displayName"),
            auth_provider=payload.get("authProvider", "email"),
            is_firebase_verified=True,
        )
    except Exception as exc:
        logger.debug("Session token verification failed: %s", exc)
        return None


def verify_firebase_id_token(id_token: str) -> Optional[Dict[str, Any]]:
    """Verifies a Firebase Auth ID token if Firebase Admin is configured."""
    if not id_token or not _ensure_firebase_initialized():
        return None
    try:
        from firebase_admin import auth as fb_auth

        return fb_auth.verify_id_token(id_token)
    except Exception as exc:
        logger.warning("Firebase token verification failed: %s", exc)
        return None


def resolve_creator_from_request(request) -> Optional[VerifiedCreator]:
    """
    Multi-mode authentication:
    1. Signed Plaans Session Token (`Authorization: Bearer plaans_jwt.<signed>`) issued by
       `/api/auth/register/`, `/api/auth/login/`, or `/api/auth/oauth/`.
    2. Firebase Auth ID Token (`Authorization: Bearer <firebase_id_token>`) verified via
       `firebase-admin` when `FIREBASE_CREDENTIALS_JSON` is configured.
    3. Graceful local/dev fallback (`Bearer local_<uid>` or `X-Plaans-Uid`).
    """
    auth_header = request.headers.get("Authorization", "")
    token = ""
    if auth_header.startswith("Bearer "):
        token = auth_header[len("Bearer ") :].strip()

    # 1. Signed session token from /api/auth/*
    if token.startswith("plaans_jwt."):
        verified_session = verify_session_token(token)
        if verified_session:
            return verified_session

    # 2. Firebase ID token
    decoded_fb = verify_firebase_id_token(token)
    if decoded_fb:
        fb_info = decoded_fb.get("firebase", {})
        sign_in_provider = (
            fb_info.get("sign_in_provider", "email")
            if isinstance(fb_info, dict)
            else "email"
        )
        return VerifiedCreator(
            uid=decoded_fb["uid"],
            email=decoded_fb.get("email"),
            display_name=decoded_fb.get("name"),
            auth_provider=sign_in_provider,
            is_firebase_verified=True,
        )

    # 3. Graceful dev/local fallback
    if token.startswith("local_"):
        return VerifiedCreator(
            uid=token,
            email=request.headers.get("X-Plaans-Email"),
            is_firebase_verified=False,
        )

    dev_uid = request.headers.get("X-Plaans-Uid", "").strip()
    if dev_uid:
        return VerifiedCreator(
            uid=dev_uid,
            email=request.headers.get("X-Plaans-Email"),
            is_firebase_verified=False,
        )

    return None
