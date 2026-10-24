from django.urls import path
from . import views

urlpatterns = [
    path("health/", views.health_check, name="health_check"),
    path("auth/register/", views.auth_register, name="auth_register"),
    path("auth/login/", views.auth_login, name="auth_login"),
    path("auth/me/", views.auth_me, name="auth_me"),
    path(
        "plans/check-slug/<str:slug>/",
        views.check_slug_availability,
        name="check_slug_availability",
    ),
    path("plans/", views.plans_collection, name="plans_collection"),
    path("plans/by-slug/<str:slug>/", views.plan_by_slug, name="plan_by_slug"),
    path(
        "plans/by-slug/<str:slug>/unlock/",
        views.unlock_plan_by_slug,
        name="unlock_plan_by_slug",
    ),
    path(
        "plans/<str:plan_id>/",
        views.delete_plan_by_id,
        name="delete_plan_by_id",
    ),
]
