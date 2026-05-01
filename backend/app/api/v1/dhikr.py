import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user
from app.core.dependencies import get_db
from app.repositories.dhikr_repository import (
    create_dhikr_reminder,
    disable_dhikr_reminder,
    get_dhikr_reminder_by_id,
    get_dhikr_reminders,
    update_dhikr_reminder,
)
from app.schemas.dhikr import (
    DhikrReminderCreate,
    DhikrReminderResponse,
    DhikrReminderUpdate,
)

router = APIRouter(prefix="/dhikr-reminders", tags=["dhikr"])


@router.get("", response_model=list[DhikrReminderResponse])
async def list_dhikr_reminders(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_dhikr_reminders(db, current_user.id)


@router.post(
    "",
    response_model=DhikrReminderResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_dhikr(
    payload: DhikrReminderCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await create_dhikr_reminder(
        db,
        current_user.id,
        payload.model_dump(),
    )


@router.patch("/{dhikr_id}", response_model=DhikrReminderResponse)
async def update_dhikr(
    dhikr_id: uuid.UUID,
    payload: DhikrReminderUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    dhikr = await get_dhikr_reminder_by_id(db, dhikr_id, current_user.id)
    if not dhikr:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dhikr reminder not found",
        )
    return await update_dhikr_reminder(
        db,
        dhikr,
        payload.model_dump(exclude_unset=True),
    )


@router.delete("/{dhikr_id}", response_model=DhikrReminderResponse)
async def disable_dhikr(
    dhikr_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    dhikr = await get_dhikr_reminder_by_id(db, dhikr_id, current_user.id)
    if not dhikr:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dhikr reminder not found",
        )
    return await disable_dhikr_reminder(db, dhikr)
