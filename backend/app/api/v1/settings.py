from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.repositories.settings_repository import get_settings_by_user_id, update_settings
from app.schemas.settings import SettingsResponse, SettingsUpdate, OnboardingRequest

router = APIRouter(prefix="/settings", tags=["settings"])


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
    updated = await update_settings(
        db,
        current_user.id,
        payload.model_dump(exclude_none=True),
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found",
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

    updated = await update_settings(db, current_user.id, data)
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found",
        )

    return updated
