import uuid
from datetime import datetime, date, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.prayer import (
    PrayerLog,
    QuranGoal,
    QuranProgress,
    RamadanFastingLog,
)
from app.services.reminder_invalidation import invalidate_target_reminders


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


async def get_quran_goal(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> QuranGoal | None:
    result = await db.execute(
        select(QuranGoal).where(QuranGoal.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def upsert_quran_goal(
    db: AsyncSession,
    user_id: uuid.UUID,
    daily_page_target: int,
) -> QuranGoal:
    goal = await get_quran_goal(db, user_id)
    if not goal:
        goal = QuranGoal(
            user_id=user_id,
            daily_page_target=daily_page_target,
        )
        db.add(goal)
    else:
        goal.daily_page_target = daily_page_target
    await db.commit()
    await db.refresh(goal)
    return goal


async def delete_quran_goal(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> bool:
    goal = await get_quran_goal(db, user_id)
    if not goal:
        return False
    await invalidate_target_reminders(
        db,
        user_id=user_id,
        target_type="quran_goal",
        target_id=goal.id,
        reason="quran_goal_disabled",
    )
    await db.delete(goal)
    await db.commit()
    return True


async def get_quran_progress_for_date(
    db: AsyncSession,
    user_id: uuid.UUID,
    progress_date: date,
) -> QuranProgress | None:
    result = await db.execute(
        select(QuranProgress).where(
            QuranProgress.user_id == user_id,
            QuranProgress.progress_date == progress_date,
        )
    )
    return result.scalar_one_or_none()


async def upsert_quran_progress(
    db: AsyncSession,
    user_id: uuid.UUID,
    progress_date: date,
    pages_completed: int,
    target_pages: int,
) -> QuranProgress:
    progress = await get_quran_progress_for_date(db, user_id, progress_date)
    if not progress:
        progress = QuranProgress(
            user_id=user_id,
            progress_date=progress_date,
            pages_completed=pages_completed,
            target_pages=target_pages,
        )
        db.add(progress)
    else:
        progress.pages_completed = pages_completed
        progress.target_pages = target_pages
    await db.commit()
    await db.refresh(progress)
    return progress


async def get_quran_progress_range(
    db: AsyncSession,
    user_id: uuid.UUID,
    date_from: date,
    date_to: date,
) -> list[QuranProgress]:
    result = await db.execute(
        select(QuranProgress).where(
            QuranProgress.user_id == user_id,
            QuranProgress.progress_date >= date_from,
            QuranProgress.progress_date <= date_to,
        ).order_by(QuranProgress.progress_date.asc())
    )
    return list(result.scalars().all())


async def get_ramadan_fasting_log(
    db: AsyncSession,
    user_id: uuid.UUID,
    fasting_date: date,
) -> RamadanFastingLog | None:
    result = await db.execute(
        select(RamadanFastingLog).where(
            RamadanFastingLog.user_id == user_id,
            RamadanFastingLog.fasting_date == fasting_date,
        )
    )
    return result.scalar_one_or_none()


async def upsert_ramadan_fasting_log(
    db: AsyncSession,
    user_id: uuid.UUID,
    fasting_date: date,
    fasted: bool,
    note: str | None,
) -> RamadanFastingLog:
    log = await get_ramadan_fasting_log(db, user_id, fasting_date)
    if not log:
        log = RamadanFastingLog(
            user_id=user_id,
            fasting_date=fasting_date,
            fasted=fasted,
            note=note,
        )
        db.add(log)
    else:
        log.fasted = fasted
        log.note = note
    await db.commit()
    await db.refresh(log)
    return log


async def get_ramadan_fasting_logs_for_month(
    db: AsyncSession,
    user_id: uuid.UUID,
    year: int,
    month: int,
) -> list[RamadanFastingLog]:
    start_date = date(year, month, 1)
    end_date = date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)
    result = await db.execute(
        select(RamadanFastingLog).where(
            RamadanFastingLog.user_id == user_id,
            RamadanFastingLog.fasting_date >= start_date,
            RamadanFastingLog.fasting_date < end_date,
        ).order_by(RamadanFastingLog.fasting_date.asc())
    )
    return list(result.scalars().all())
