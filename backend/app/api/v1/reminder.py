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
    dismiss_reminder,
    get_reminder_by_id,
    get_reminders,
    replace_task_reminder_presets,
    reschedule_reminder,
    snooze_reminder,
    update_reminder,
)
from app.repositories.task_repository import get_task_by_id
from app.schemas.reminder import (
    ReminderCreate,
    ReminderRescheduleRequest,
    ReminderResponse,
    ReminderSnoozeRequest,
    TaskReminderPresetRequest,
    ReminderUpdate,
    TARGET_TYPES_REQUIRING_ID,
)
from app.services.task_reminder_presets import build_task_reminder_preset_data

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


@router.post("/task-presets", response_model=list[ReminderResponse])
async def create_task_reminder_presets(
    payload: TaskReminderPresetRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, payload.task_id, current_user.id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder target not found",
        )
    if any(item.is_persistent for item in payload.presets) and task.priority != "high":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Persistent reminders are allowed for high-priority tasks only",
        )
    try:
        reminders_data = build_task_reminder_preset_data(
            task_id=task.id,
            due_at=task.due_at,
            timezone_name=payload.timezone,
            presets=payload.presets,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    return await replace_task_reminder_presets(
        db,
        current_user.id,
        task,
        reminders_data,
    )


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


@router.post("/{reminder_id}/snooze", response_model=ReminderResponse)
async def snooze_existing_reminder(
    reminder_id: uuid.UUID,
    payload: ReminderSnoozeRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reminder = await get_reminder_by_id(db, reminder_id, current_user.id)
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found",
        )
    return await snooze_reminder(db, reminder, payload.minutes)


@router.post("/{reminder_id}/reschedule", response_model=ReminderResponse)
async def reschedule_existing_reminder(
    reminder_id: uuid.UUID,
    payload: ReminderRescheduleRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reminder = await get_reminder_by_id(db, reminder_id, current_user.id)
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found",
        )
    return await reschedule_reminder(db, reminder, payload.scheduled_at)


@router.post("/{reminder_id}/dismiss", response_model=ReminderResponse)
async def dismiss_existing_reminder(
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
    return await dismiss_reminder(db, reminder)


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
        task = await get_task_by_id(db, payload.target_id, user_id)
        target_exists = task is not None
        if task is not None and payload.is_persistent and task.priority != "high":
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Persistent reminders are allowed for high-priority tasks only",
            )
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
