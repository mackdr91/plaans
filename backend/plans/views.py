from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .auth import (
    issue_session_token,
    resolve_creator_from_request,
)
from .mongo_repo import repo


@api_view(["GET"])
def health_check(request):
    """Health check endpoint reporting Django & MongoDB status."""
    return Response(
        {
            "status": "ok",
            "service": "plaans-django-mongodb-api",
            "storageEngine": repo.storage_engine,
            "authProviders": ["email"],
        }
    )


@api_view(["POST"])
def auth_register(request):
    """
    `POST /api/auth/register/`
    Creates a new Creator account with Email & Password in MongoDB (`plaans_db.users`),
    returning `{ "token": "plaans_jwt...", "user": { ... } }`.
    """
    data = request.data if isinstance(request.data, dict) else {}
    email = str(data.get("email", "")).strip()
    password = str(data.get("password", ""))
    display_name = str(data.get("displayName", "")).strip() or None

    user_doc, err = repo.create_email_user(
        email=email,
        password=password,
        display_name=display_name,
    )
    if err or not user_doc:
        return Response(
            {"error": err or "Could not create account."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    token = issue_session_token(user_doc)
    return Response(
        {"token": token, "user": user_doc},
        status=status.HTTP_201_CREATED,
    )


@api_view(["POST"])
def auth_login(request):
    """
    `POST /api/auth/login/`
    Authenticates an existing Creator account with Email & Password against MongoDB,
    returning `{ "token": "plaans_jwt...", "user": { ... } }`.
    """
    data = request.data if isinstance(request.data, dict) else {}
    email = str(data.get("email", "")).strip()
    password = str(data.get("password", ""))

    user_doc, err = repo.authenticate_email_user(email=email, password=password)
    if err or not user_doc:
        return Response(
            {"error": err or "Invalid email or password."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    token = issue_session_token(user_doc)
    return Response(
        {"token": token, "user": user_doc},
        status=status.HTTP_200_OK,
    )


@api_view(["GET"])
def auth_me(request):
    """
    `GET /api/auth/me/`
    Returns the currently authenticated Creator's profile and cloud-synced plans count.
    """
    creator = resolve_creator_from_request(request)
    if not creator:
        return Response(
            {"error": "Authentication required."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    user_doc = repo.get_user_by_uid(creator.uid)
    plans = repo.list_plans_for_owner(creator.uid)
    if not user_doc:
        user_doc = {
            "uid": creator.uid,
            "email": creator.email or "",
            "displayName": creator.display_name
            or (creator.email.split("@")[0] if creator.email else "Creator"),
            "authProvider": creator.auth_provider,
            "photoUrl": None,
        }

    return Response(
        {
            "user": user_doc,
            "cloudPlansCount": len(plans),
        },
        status=status.HTTP_200_OK,
    )


@api_view(["GET"])
def check_slug_availability(request, slug: str):
    """Live vanity slug check (`GET /api/plans/check-slug/<slug>/`)."""
    exclude_id = request.query_params.get("excludeId")
    available = repo.is_slug_available(slug, exclude_plan_id=exclude_id)
    return Response(
        {
            "slug": slug.strip().lower(),
            "available": available,
        }
    )


@api_view(["GET", "POST"])
def plans_collection(request):
    """
    - `GET /api/plans/`: Returns all cloud-synced plans belonging to the authenticated creator.
    - `POST /api/plans/`: Creates or updates a plan in MongoDB (`PlanModel` JSON payload).
    """
    creator = resolve_creator_from_request(request)
    if not creator:
        return Response(
            {"error": "Authentication required. Sign in with Firebase or provide X-Plaans-Uid."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    if request.method == "GET":
        plans = repo.list_plans_for_owner(creator.uid)
        return Response({"plans": plans, "ownerUid": creator.uid})

    payload = request.data
    if not isinstance(payload, dict):
        return Response(
            {"error": "Expected JSON object representing a PlanModel."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    saved, err = repo.upsert_plan(
        payload,
        owner_uid=creator.uid,
        owner_email=creator.email,
    )
    if err:
        return Response({"error": err}, status=status.HTTP_409_CONFLICT)

    return Response({"plan": saved}, status=status.HTTP_200_OK)


@api_view(["GET"])
def plan_by_slug(request, slug: str):
    """
    Resolves `plaans.co/<slug>` (`GET /api/plans/by-slug/<slug>/`).
    If the plan is `pinProtected`, returns metadata + `requiresPin: True` without leaking blocks
    unless the requester is the owner or passes a valid `?pin=` query parameter.
    """
    doc = repo.get_plan_by_slug(slug, increment_views=True)
    if not doc:
        return Response(
            {"error": f"No plan found for slug '{slug}'."},
            status=status.HTTP_404_NOT_FOUND,
        )

    creator = resolve_creator_from_request(request)
    is_owner = creator is not None and creator.uid == doc.get("ownerUid")
    visibility = doc.get("visibility", "public")

    if visibility == "pinProtected" and not is_owner:
        supplied_pin = request.query_params.get("pin", "")
        if not supplied_pin or not repo.verify_plan_pin(doc, supplied_pin):
            return Response(
                {
                    "requiresPin": True,
                    "slug": doc.get("slug"),
                    "title": doc.get("title"),
                    "subtitle": doc.get("subtitle"),
                    "authorName": doc.get("authorName"),
                    "visibility": visibility,
                },
                status=status.HTTP_200_OK,
            )

    sanitized = repo._sanitize_for_response(doc)
    return Response({"requiresPin": False, "plan": sanitized})


@api_view(["POST"])
def unlock_plan_by_slug(request, slug: str):
    """Verifies a 4–6 digit trip PIN (`POST /api/plans/by-slug/<slug>/unlock/`)."""
    doc = repo.get_plan_by_slug(slug, increment_views=False)
    if not doc:
        return Response(
            {"error": f"No plan found for slug '{slug}'."},
            status=status.HTTP_404_NOT_FOUND,
        )

    pin_code = str(request.data.get("pinCode", "")).strip()
    if not repo.verify_plan_pin(doc, pin_code):
        return Response(
            {"error": "Incorrect PIN code for this plan."},
            status=status.HTTP_403_FORBIDDEN,
        )

    sanitized = repo._sanitize_for_response(doc)
    return Response({"requiresPin": False, "plan": sanitized})


@api_view(["DELETE"])
def delete_plan_by_id(request, plan_id: str):
    """Deletes a plan owned by the authenticated creator."""
    creator = resolve_creator_from_request(request)
    if not creator:
        return Response(
            {"error": "Authentication required."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    deleted = repo.delete_plan(plan_id, owner_uid=creator.uid)
    if not deleted:
        return Response(
            {"error": "Plan not found or not owned by you."},
            status=status.HTTP_404_NOT_FOUND,
        )
    return Response({"deleted": True, "id": plan_id})
