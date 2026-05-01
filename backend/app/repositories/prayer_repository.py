import uuid
from collections import defaultdict
from datetime import datetime, date, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.prayer import (
    PrayerLog,
    QuranGoal,
    QuranProgress,
    RamadanFastingLog,
)
from app.services.reminder_invalidation import invalidate_target_reminders


# ── Prayer Log helpers ───────────────────────────────────────────────────────

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
    if log.status not in ("prayed_on_time", "prayed_late"):
        log.status = "prayed_on_time"
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
    log.status = None
    await db.commit()
    await db.refresh(log)
    return log


VALID_PRAYER_STATUSES = {"prayed_on_time", "prayed_late", "missed", "excused"}


async def mark_prayer_status(
    db: AsyncSession,
    log: PrayerLog,
    status: str,
) -> PrayerLog:
    """Set an explicit status on a prayer log.

    For 'missed' or 'excused': marks completed=False and clears timestamps.
    For 'prayed_on_time' or 'prayed_late': marks completed=True with now.
    """
    if status not in VALID_PRAYER_STATUSES:
        raise ValueError(f"Invalid prayer status: {status}")
    log.status = status
    if status in ("prayed_on_time", "prayed_late"):
        log.completed = True
        if log.completed_at is None:
            log.completed_at = datetime.now(timezone.utc)
        log.completion_source = "manual"
    else:
        # missed / excused
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


async def get_prayer_weekly_summary(
    db: AsyncSession,
    user_id: uuid.UUID,
    week_start: date,
    week_end: date,
) -> dict:
    """Aggregate prayer status counts per day across a date range.

    Returns a dict with keys:
      - days: list of per-day dicts (prayer_date, total, completed, missed, late, excused)
      - total_missed, total_completed, total_prayers, today_missed
    """
    logs = await get_prayer_history(db, user_id, week_start, week_end)

    by_date: dict[date, list[PrayerLog]] = defaultdict(list)
    for log in logs:
        by_date[log.prayer_date].append(log)

    today = date.today()
    days = []
    total_missed = 0
    total_completed = 0
    total_prayers = 0
    today_missed = 0

    for offset in range((week_end - week_start).days + 1):
        current = week_start + timedelta(days=offset)
        day_logs = by_date.get(current, [])
        completed = sum(1 for l in day_logs if l.completed)
        missed = sum(1 for l in day_logs if l.status == "missed")
        late = sum(1 for l in day_logs if l.status == "prayed_late")
        excused = sum(1 for l in day_logs if l.status == "excused")
        total = len(day_logs)
        days.append(
            {
                "prayer_date": current,
                "total": total,
                "completed": completed,
                "missed": missed,
                "late": late,
                "excused": excused,
            }
        )
        total_missed += missed
        total_completed += completed
        total_prayers += total
        if current == today:
            today_missed = missed

    return {
        "week_start": week_start,
        "week_end": week_end,
        "total_missed": total_missed,
        "total_completed": total_completed,
        "total_prayers": total_prayers,
        "today_missed": today_missed,
        "days": days,
    }


# ── Quran Goal helpers ───────────────────────────────────────────────────────

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


# ── Ramadan Fasting Log helpers ──────────────────────────────────────────────

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
