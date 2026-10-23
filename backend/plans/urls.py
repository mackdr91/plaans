from django.urls import path
from . import views

urlpatterns = [
    path("health/", views.health_check, name="health_check"),
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
