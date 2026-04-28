import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user
from app.core.dependencies import get_db
from app.repositories.focus_repository import get_session_by_id
from app.repositories.habit_repository import get_habit_by_id
from app.repositories.note_repository import get_note_by_id
from app.repositories.prayer_repository import get_quran_goal
from app.repositories.reminder_repository import (
    create_reminder,
    get_reminder_by_id,
    get_reminders,
    update_reminder,
)
from app.repositories.task_repository import get_task_by_id
from app.schemas.reminder import (
    ReminderCreate,
    ReminderResponse,
    ReminderUpdate,
    TARGET_TYPES_REQUIRING_ID,
)

router = APIRouter(prefix="/reminders", tags=["reminders"])


@router.get("", response_model=list[ReminderResponse])
async def list_reminders(
    target_type: Optional[str] = Query(None),
    target_id: Optional[uuid.UUID] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_reminders(
        db,
        current_user.id,
        target_type=target_type,
        target_id=target_id,
        status=status_filter,
    )


@router.post("", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_new_reminder(
    payload: ReminderCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _validate_target_ownership(db, current_user.id, payload)
    return await create_reminder(db, current_user.id, payload.model_dump())


@router.get("/{reminder_id}", response_model=ReminderResponse)
async def get_reminder(
    reminder_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reminder = await get_reminder_by_id(db, reminder_id, current_user.id)
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found",
        )
    return reminder


@router.patch("/{reminder_id}", response_model=ReminderResponse)
async def update_existing_reminder(
    reminder_id: uuid.UUID,
    payload: ReminderUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reminder = await get_reminder_by_id(db, reminder_id, current_user.id)
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found",
        )
    return await update_reminder(
        db,
        reminder,
        payload.model_dump(exclude_unset=True),
    )


async def _validate_target_ownership(
    db: AsyncSession,
    user_id: uuid.UUID,
    payload: ReminderCreate,
) -> None:
    if payload.target_type in TARGET_TYPES_REQUIRING_ID and payload.target_id is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="target_id is required for this reminder target_type",
        )

    if payload.target_id is None:
        return

    target_exists = True
    if payload.target_type == "task":
        target_exists = await get_task_by_id(db, payload.target_id, user_id) is not None
    elif payload.target_type == "habit":
        target_exists = await get_habit_by_id(db, payload.target_id, user_id) is not None
    elif payload.target_type == "note":
        target_exists = await get_note_by_id(db, payload.target_id, user_id) is not None
    elif payload.target_type == "quran_goal":
        goal = await get_quran_goal(db, user_id)
        target_exists = goal is not None and goal.id == payload.target_id
    elif payload.target_type == "focus":
        target_exists = (
            await get_session_by_id(db, payload.target_id, user_id) is not None
        )

    if not target_exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder target not found",
        )
