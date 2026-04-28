from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.repositories.settings_repository import get_settings_by_user_id, update_settings
from app.schemas.settings import SettingsResponse, SettingsUpdate, OnboardingRequest
from app.services.ai_recommendation_seed import build_ai_recommendation_seed
from app.services.onboarding_defaults import create_default_habits_for_goals
from app.services.reminder_lifecycle import log_prayer_reminders_invalidated

router = APIRouter(prefix="/settings", tags=["settings"])

AI_SEED_FIELDS = {"goals", "wake_time", "sleep_time", "timezone"}
PRAYER_REMINDER_FIELDS = {
    "prayer_calculation_method",
    "prayer_location_lat",
    "prayer_location_lng",
    "prayer_reminder_minutes_before",
    "athan_sound_enabled",
    "timezone",
    "reminder_preferences",
}


@router.get("", response_model=SettingsResponse)
async def get_settings(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await get_settings_by_user_id(db, current_user.id)
    if not settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found",
        )
    return settings


@router.patch("", response_model=SettingsResponse)
async def update_user_settings(
    payload: SettingsUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await get_settings_by_user_id(db, current_user.id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found",
        )

    data = payload.model_dump(exclude_none=True, mode="json")
    if AI_SEED_FIELDS.intersection(data):
        data.update(
            build_ai_recommendation_seed(
                goals=data.get("goals", existing.goals),
                wake_time=data.get("wake_time", existing.wake_time),
                sleep_time=data.get("sleep_time", existing.sleep_time),
                timezone_name=data.get("timezone", existing.timezone),
            )
        )
    if PRAYER_REMINDER_FIELDS.intersection(data):
        log_prayer_reminders_invalidated(
            user_id=current_user.id,
            reason="settings_changed",
        )

    updated = await update_settings(
        db,
        current_user.id,
        data,
    )
    return updated


@router.post("/onboarding", response_model=SettingsResponse)
async def complete_onboarding(
    payload: OnboardingRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Save the authenticated user's onboarding choices and mark onboarding done.
    """
    data = payload.model_dump(mode="json")
    data["onboarding_completed"] = True
    data.update(
        build_ai_recommendation_seed(
            goals=data["goals"],
            wake_time=data.get("wake_time"),
            sleep_time=data.get("sleep_time"),
            timezone_name=data["timezone"],
        )
    )

    updated = await update_settings(db, current_user.id, data)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found",
        )

    await create_default_habits_for_goals(db, current_user.id, data["goals"])

    return updated
