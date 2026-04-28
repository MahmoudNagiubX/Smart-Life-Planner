import uuid
from datetime import datetime, timezone
from typing import Any, Iterable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.reminder import Reminder

ACTIVE_REMINDER_STATUSES = {"scheduled", "snoozed", "sent", "failed"}

PREFERENCE_TARGET_TYPES = {
    "task": {"task"},
    "habit": {"habit"},
    "note": {"note"},
    "quran_goal": {"quran_goal"},
    "prayer": {"prayer", "ramadan"},
    "focus_prompt": {"focus"},
    "bedtime": {"bedtime"},
    "ai_suggestion": {"ai_suggestion"},
    "location": {"location"},
}


def disabled_preference_target_types(
    reminder_preferences: dict[str, Any] | None,
    *,
    notifications_enabled: bool | None = None,
) -> set[str]:
    if notifications_enabled is False:
        return set().union(*PREFERENCE_TARGET_TYPES.values())

    types = (reminder_preferences or {}).get("types")
    if not isinstance(types, dict):
        return set()

    disabled: set[str] = set()
    for key, targets in PREFERENCE_TARGET_TYPES.items():
        if types.get(key) is False:
            disabled.update(targets)
    return disabled


async def invalidate_target_reminders(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    target_type: str,
    target_id: uuid.UUID | None = None,
    reason: str,
) -> int:
    query = _active_reminders_query(user_id).where(Reminder.target_type == target_type)
    if target_id is not None:
        query = query.where(Reminder.target_id == target_id)
    reminders = await _reminders_for_query(db, query)
    return await _cancel_reminders(db, reminders, reason)


async def invalidate_target_types(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    target_types: Iterable[str],
    reason: str,
) -> int:
    normalized = {target_type for target_type in target_types if target_type}
    if not normalized:
        return 0
    query = _active_reminders_query(user_id).where(
        Reminder.target_type.in_(normalized)
    )
    reminders = await _reminders_for_query(db, query)
    return await _cancel_reminders(db, reminders, reason)


async def update_active_reminder_timezone(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    timezone_name: str,
) -> int:
    reminders = await _reminders_for_query(db, _active_reminders_query(user_id))
    for reminder in reminders:
        reminder.timezone = timezone_name
    if reminders:
        await db.commit()
    return len(reminders)


def _active_reminders_query(user_id: uuid.UUID):
    return select(Reminder).where(
        Reminder.user_id == user_id,
        Reminder.status.in_(ACTIVE_REMINDER_STATUSES),
        Reminder.cancelled_at.is_(None),
        Reminder.dismissed_at.is_(None),
    )


async def _reminders_for_query(db: AsyncSession, query) -> list[Reminder]:
    result = await db.execute(query)
    return list(result.scalars().all())


async def _cancel_reminders(
    db: AsyncSession,
    reminders: list[Reminder],
    reason: str,
) -> int:
    now = datetime.now(timezone.utc)
    for reminder in reminders:
        reminder.status = "cancelled"
        reminder.cancelled_at = now
        reminder.snooze_until = None
        if reminder.recurrence_rule:
            reminder.recurrence_rule = f"{reminder.recurrence_rule};invalidated={reason}"
        else:
            reminder.recurrence_rule = f"invalidated={reason}"
    if reminders:
        await db.commit()
    return len(reminders)
