import uuid
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.dhikr import DhikrReminder
from app.models.reminder import Reminder
from app.services.reminder_invalidation import invalidate_target_reminders

ACTIVE_REMINDER_STATUSES = {"scheduled", "snoozed", "sent", "failed"}


async def get_dhikr_reminders(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> list[DhikrReminder]:
    result = await db.execute(
        select(DhikrReminder)
        .where(DhikrReminder.user_id == user_id)
        .order_by(DhikrReminder.enabled.desc(), DhikrReminder.schedule_time.asc())
    )
    return list(result.scalars().all())


async def get_dhikr_reminder_by_id(
    db: AsyncSession,
    reminder_id: uuid.UUID,
    user_id: uuid.UUID,
) -> DhikrReminder | None:
    result = await db.execute(
        select(DhikrReminder).where(
            DhikrReminder.id == reminder_id,
            DhikrReminder.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_dhikr_reminder(
    db: AsyncSession,
    user_id: uuid.UUID,
    data: dict,
) -> DhikrReminder:
    dhikr = DhikrReminder(user_id=user_id, **data)
    db.add(dhikr)
    await db.flush()
    await _sync_unified_dhikr_reminder(db, dhikr)
    await db.commit()
    await db.refresh(dhikr)
    return dhikr


async def update_dhikr_reminder(
    db: AsyncSession,
    dhikr: DhikrReminder,
    data: dict,
) -> DhikrReminder:
    for key, value in data.items():
        setattr(dhikr, key, value)

    if dhikr.enabled:
        await _sync_unified_dhikr_reminder(db, dhikr)
    else:
        await invalidate_target_reminders(
            db,
            user_id=dhikr.user_id,
            target_type="dhikr",
            target_id=dhikr.id,
            reason="dhikr_disabled",
        )

    await db.commit()
    await db.refresh(dhikr)
    return dhikr


async def disable_dhikr_reminder(
    db: AsyncSession,
    dhikr: DhikrReminder,
) -> DhikrReminder:
    dhikr.enabled = False
    await invalidate_target_reminders(
        db,
        user_id=dhikr.user_id,
        target_type="dhikr",
        target_id=dhikr.id,
        reason="dhikr_disabled",
    )
    await db.commit()
    await db.refresh(dhikr)
    return dhikr


async def _sync_unified_dhikr_reminder(
    db: AsyncSession,
    dhikr: DhikrReminder,
) -> None:
    scheduled_at = next_dhikr_occurrence(
        dhikr.schedule_time,
        timezone_name=dhikr.timezone,
        recurrence_rule=dhikr.recurrence_rule,
    )
    result = await db.execute(
        select(Reminder).where(
            Reminder.user_id == dhikr.user_id,
            Reminder.target_type == "dhikr",
            Reminder.target_id == dhikr.id,
            Reminder.reminder_type == "dhikr",
            Reminder.status.in_(ACTIVE_REMINDER_STATUSES),
            Reminder.cancelled_at.is_(None),
            Reminder.dismissed_at.is_(None),
        )
    )
    reminders = list(result.scalars().all())
    primary = reminders[0] if reminders else None
    if primary is None:
        db.add(
            Reminder(
                user_id=dhikr.user_id,
                target_type="dhikr",
                target_id=dhikr.id,
                reminder_type="dhikr",
                scheduled_at=scheduled_at,
                recurrence_rule=dhikr.recurrence_rule,
                timezone=dhikr.timezone,
                channel="local",
                priority="normal",
                status="scheduled",
            )
        )
    else:
        primary.scheduled_at = scheduled_at
        primary.recurrence_rule = dhikr.recurrence_rule
        primary.timezone = dhikr.timezone
        primary.status = "scheduled"
        primary.cancelled_at = None
        primary.dismissed_at = None
        primary.snooze_until = None

    now = datetime.now(timezone.utc)
    for duplicate in reminders[1:]:
        duplicate.status = "cancelled"
        duplicate.cancelled_at = now
        duplicate.snooze_until = None


def next_dhikr_occurrence(
    schedule_time: time,
    *,
    timezone_name: str,
    recurrence_rule: str,
    now: datetime | None = None,
) -> datetime:
    zone = _zone_or_utc(timezone_name)
    current = now.astimezone(zone) if now else datetime.now(zone)
    scheduled = datetime.combine(current.date(), schedule_time, tzinfo=zone)
    if scheduled <= current:
        scheduled = scheduled + timedelta(days=1)
    if recurrence_rule == "weekdays":
        while scheduled.weekday() >= 5:
            scheduled = scheduled + timedelta(days=1)
    return scheduled.astimezone(timezone.utc)


def _zone_or_utc(timezone_name: str) -> ZoneInfo:
    try:
        return ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError:
        return ZoneInfo("UTC")
