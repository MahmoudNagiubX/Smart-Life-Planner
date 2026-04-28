import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.reminder import Reminder
from app.models.task import Task
from app.services.reminder_invalidation import invalidate_target_reminders
from app.services.task_reminder_presets import (
    TASK_REMINDER_PRESET_OFFSETS,
    calculate_task_preset_time,
    is_future_reminder,
    task_preset_from_recurrence_rule,
)


async def get_reminders(
    db: AsyncSession,
    user_id: uuid.UUID,
    target_type: Optional[str] = None,
    target_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
) -> list[Reminder]:
    query = (
        select(Reminder)
        .where(Reminder.user_id == user_id)
        .order_by(Reminder.scheduled_at.asc(), Reminder.created_at.desc())
    )
    if target_type:
        query = query.where(Reminder.target_type == target_type)
    if target_id:
        query = query.where(Reminder.target_id == target_id)
    if status:
        query = query.where(Reminder.status == status)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_reminder_by_id(
    db: AsyncSession,
    reminder_id: uuid.UUID,
    user_id: uuid.UUID,
) -> Reminder | None:
    result = await db.execute(
        select(Reminder).where(
            Reminder.id == reminder_id,
            Reminder.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_reminder(
    db: AsyncSession,
    user_id: uuid.UUID,
    data: dict,
) -> Reminder:
    reminder = Reminder(user_id=user_id, **data)
    db.add(reminder)
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def replace_task_reminder_presets(
    db: AsyncSession,
    user_id: uuid.UUID,
    task: Task,
    reminders_data: list[dict],
) -> list[Reminder]:
    now = datetime.now(timezone.utc)
    existing = await _get_active_task_preset_reminders(db, user_id, task.id)
    for reminder in existing:
        reminder.status = "cancelled"
        reminder.cancelled_at = now

    created: list[Reminder] = []
    for data in reminders_data:
        if not is_future_reminder(data["scheduled_at"]):
            continue
        reminder = Reminder(user_id=user_id, **data)
        db.add(reminder)
        created.append(reminder)

    await db.commit()
    for reminder in created:
        await db.refresh(reminder)
    return created


async def resync_task_due_preset_reminders(
    db: AsyncSession,
    task: Task,
) -> None:
    reminders = await _get_active_task_preset_reminders(db, task.user_id, task.id)
    if not reminders:
        return

    now = datetime.now(timezone.utc)
    changed = False
    for reminder in reminders:
        preset = task_preset_from_recurrence_rule(reminder.recurrence_rule)
        if preset not in TASK_REMINDER_PRESET_OFFSETS:
            continue

        if task.due_at is None:
            reminder.status = "cancelled"
            reminder.cancelled_at = now
            changed = True
            continue

        next_time = calculate_task_preset_time(
            preset,
            due_at=task.due_at,
        )
        if is_future_reminder(next_time):
            reminder.scheduled_at = next_time
            reminder.cancelled_at = None
            reminder.status = "scheduled"
        else:
            reminder.status = "cancelled"
            reminder.cancelled_at = now
        changed = True

    if changed:
        await db.commit()


async def invalidate_task_reminders(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    task_id: uuid.UUID,
    reason: str,
) -> int:
    return await invalidate_target_reminders(
        db,
        user_id=user_id,
        target_type="task",
        target_id=task_id,
        reason=reason,
    )


async def update_reminder(
    db: AsyncSession,
    reminder: Reminder,
    data: dict,
) -> Reminder:
    for key, value in data.items():
        setattr(reminder, key, value)
    if data.get("status") == "scheduled":
        reminder.snooze_until = None
        reminder.cancelled_at = None
        reminder.dismissed_at = None
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def snooze_reminder(
    db: AsyncSession,
    reminder: Reminder,
    minutes: int,
) -> Reminder:
    snooze_until = datetime.now(timezone.utc) + timedelta(minutes=minutes)
    reminder.scheduled_at = snooze_until
    reminder.snooze_until = snooze_until
    reminder.status = "snoozed"
    reminder.cancelled_at = None
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def reschedule_reminder(
    db: AsyncSession,
    reminder: Reminder,
    scheduled_at: datetime,
) -> Reminder:
    reminder.scheduled_at = scheduled_at
    reminder.snooze_until = None
    reminder.status = "scheduled"
    reminder.cancelled_at = None
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def dismiss_reminder(
    db: AsyncSession,
    reminder: Reminder,
) -> Reminder:
    now = datetime.now(timezone.utc)
    reminder.status = "dismissed"
    reminder.dismissed_at = now
    reminder.cancelled_at = now
    reminder.snooze_until = None
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def _get_active_task_preset_reminders(
    db: AsyncSession,
    user_id: uuid.UUID,
    task_id: uuid.UUID,
) -> list[Reminder]:
    result = await db.execute(
        select(Reminder).where(
            Reminder.user_id == user_id,
            Reminder.target_type == "task",
            Reminder.target_id == task_id,
            Reminder.reminder_type == "task_due",
            Reminder.status != "cancelled",
            Reminder.recurrence_rule.like("preset:%"),
        )
    )
    return list(result.scalars().all())
