import logging
from dataclasses import dataclass
from typing import Optional
from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


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
    is_firebase_verified: bool = False


def resolve_creator_from_request(request) -> Optional[VerifiedCreator]:
    """
    Dual-mode authentication:
    1. If `Authorization: Bearer <firebase_id_token>` is present and Firebase Admin is configured,
       verifies the JWT against Firebase Auth.
    2. In local/dev mode (or when Firebase Admin credentials aren't configured yet),
       accepts `X-Plaans-Uid` / `Bearer local_<uid>` so local creators can test full cloud sync.
    """
    auth_header = request.headers.get("Authorization", "")
    token = ""
    if auth_header.startswith("Bearer "):
        token = auth_header[len("Bearer ") :].strip()

    if token and _ensure_firebase_initialized():
        try:
            from firebase_admin import auth as fb_auth

            decoded = fb_auth.verify_id_token(token)
            return VerifiedCreator(
                uid=decoded["uid"],
                email=decoded.get("email"),
                is_firebase_verified=True,
            )
        except Exception as exc:
            logger.warning("Firebase token verification failed: %s", exc)

    # Graceful dev/local fallback
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
