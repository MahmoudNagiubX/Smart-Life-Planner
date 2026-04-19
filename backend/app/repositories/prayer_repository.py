import uuid
from datetime import datetime, date, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.prayer import PrayerLog


async def get_prayer_logs_for_date(
    db: AsyncSession,
    user_id: uuid.UUID,
    prayer_date: date,
) -> list[PrayerLog]:
    result = await db.execute(
        select(PrayerLog).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date == prayer_date,
        ).order_by(PrayerLog.scheduled_at.asc())
    )
    return list(result.scalars().all())


async def get_prayer_log(
    db: AsyncSession,
    user_id: uuid.UUID,
    prayer_name: str,
    prayer_date: date,
) -> PrayerLog | None:
    result = await db.execute(
        select(PrayerLog).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_name == prayer_name,
            PrayerLog.prayer_date == prayer_date,
        )
    )
    return result.scalar_one_or_none()


async def upsert_prayer_log(
    db: AsyncSession,
    user_id: uuid.UUID,
    prayer_name: str,
    prayer_date: date,
    scheduled_at: datetime | None,
) -> PrayerLog:
    log = await get_prayer_log(db, user_id, prayer_name, prayer_date)
    if not log:
        log = PrayerLog(
            user_id=user_id,
            prayer_name=prayer_name,
            prayer_date=prayer_date,
            scheduled_at=scheduled_at,
        )
        db.add(log)
        await db.commit()
        await db.refresh(log)
    return log


async def mark_prayer_complete(
    db: AsyncSession,
    log: PrayerLog,
) -> PrayerLog:
    log.completed = True
    log.completed_at = datetime.now(timezone.utc)
    log.completion_source = "manual"
    await db.commit()
    await db.refresh(log)
    return log


async def mark_prayer_incomplete(
    db: AsyncSession,
    log: PrayerLog,
) -> PrayerLog:
    log.completed = False
    log.completed_at = None
    log.completion_source = None
    await db.commit()
    await db.refresh(log)
    return log


async def get_prayer_history(
    db: AsyncSession,
    user_id: uuid.UUID,
    date_from: date,
    date_to: date,
) -> list[PrayerLog]:
    result = await db.execute(
        select(PrayerLog).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date >= date_from,
            PrayerLog.prayer_date <= date_to,
        ).order_by(PrayerLog.prayer_date.desc(), PrayerLog.scheduled_at.asc())
    )
    return list(result.scalars().all())