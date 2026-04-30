import uuid
from datetime import date, datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.focus import FocusSession
from app.models.task import Task
from app.models.user import UserSettings
from app.services.pomodoro_progress import next_completed_pomodoro_count


async def get_active_session(
    db: AsyncSession, user_id: uuid.UUID
) -> FocusSession | None:
    result = await db.execute(
        select(FocusSession).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "active",
        )
    )
    return result.scalar_one_or_none()


async def get_sessions(
    db: AsyncSession, user_id: uuid.UUID
) -> list[FocusSession]:
    result = await db.execute(
        select(FocusSession)
        .where(FocusSession.user_id == user_id)
        .order_by(FocusSession.started_at.desc())
        .limit(20)
    )
    return list(result.scalars().all())


async def get_focus_settings(
    db: AsyncSession, user_id: uuid.UUID
) -> UserSettings | None:
    result = await db.execute(
        select(UserSettings).where(UserSettings.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def update_focus_settings(
    db: AsyncSession, user_id: uuid.UUID, data: dict
) -> UserSettings | None:
    settings = await get_focus_settings(db, user_id)
    if not settings:
        return None
    for key, value in data.items():
        if value is not None:
            setattr(settings, key, value)
    await db.commit()
    await db.refresh(settings)
    return settings


async def get_session_by_id(
    db: AsyncSession, session_id: uuid.UUID, user_id: uuid.UUID
) -> FocusSession | None:
    result = await db.execute(
        select(FocusSession).where(
            FocusSession.id == session_id,
            FocusSession.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_session(
    db: AsyncSession, user_id: uuid.UUID, data: dict
) -> FocusSession:
    session = FocusSession(user_id=user_id, **data)
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def complete_session(
    db: AsyncSession, session: FocusSession
) -> FocusSession:
    now = datetime.now(timezone.utc)
    session.status = "completed"
    session.ended_at = now
    elapsed = now - session.started_at.replace(tzinfo=timezone.utc)
    session.actual_minutes = max(1, int(elapsed.total_seconds() / 60))
    if session.task_id and session.session_type not in {"short_break", "long_break"}:
        task = await _get_linked_task_for_session(db, session)
        if task:
            task.completed_pomodoros = next_completed_pomodoro_count(
                task.completed_pomodoros,
                task.estimated_pomodoros,
            )
    await db.commit()
    await db.refresh(session)
    return session


async def _get_linked_task_for_session(
    db: AsyncSession, session: FocusSession
) -> Task | None:
    result = await db.execute(
        select(Task).where(
            Task.id == session.task_id,
            Task.user_id == session.user_id,
            Task.is_deleted == False,
        )
    )
    return result.scalar_one_or_none()


async def cancel_session(
    db: AsyncSession, session: FocusSession
) -> FocusSession:
    now = datetime.now(timezone.utc)
    session.status = "cancelled"
    session.ended_at = now
    elapsed = now - session.started_at.replace(tzinfo=timezone.utc)
    session.actual_minutes = max(0, int(elapsed.total_seconds() / 60))
    await db.commit()
    await db.refresh(session)
    return session


async def get_focus_analytics(
    db: AsyncSession, user_id: uuid.UUID
) -> dict:
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=7)

    today_result = await db.execute(
        select(
            func.coalesce(func.sum(FocusSession.actual_minutes), 0),
            func.count(FocusSession.id),
        ).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
            FocusSession.started_at >= today_start,
        )
    )
    today_minutes, today_sessions = today_result.one()

    week_result = await db.execute(
        select(
            func.coalesce(func.sum(FocusSession.actual_minutes), 0),
            func.count(FocusSession.id),
        ).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
            FocusSession.started_at >= week_start,
        )
    )
    week_minutes, week_sessions = week_result.one()

    all_result = await db.execute(
        select(
            func.coalesce(func.sum(FocusSession.actual_minutes), 0),
            func.count(FocusSession.id),
        ).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
        )
    )
    total_minutes, completed_sessions = all_result.one()

    days_result = await db.execute(
        select(func.date(FocusSession.started_at))
        .where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
        )
        .group_by(func.date(FocusSession.started_at))
        .order_by(func.date(FocusSession.started_at))
    )
    def _to_date(value) -> date:
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        return datetime.fromisoformat(str(value)).date()

    focus_days = sorted({_to_date(row[0]) for row in days_result.all()})
    focus_day_set = set(focus_days)

    current_streak = 0
    cursor = now.date()
    if cursor not in focus_day_set and cursor - timedelta(days=1) in focus_day_set:
        cursor = cursor - timedelta(days=1)
    while cursor in focus_day_set:
        current_streak += 1
        cursor = cursor - timedelta(days=1)

    longest_streak = 0
    running_streak = 0
    previous_day = None
    for focus_day in focus_days:
        if previous_day and focus_day == previous_day + timedelta(days=1):
            running_streak += 1
        else:
            running_streak = 1
        longest_streak = max(longest_streak, running_streak)
        previous_day = focus_day

    average_session_minutes = (
        int(total_minutes / completed_sessions) if completed_sessions else 0
    )
    if today_sessions:
        report_summary = (
            f"Completed {today_sessions} focus session"
            f"{'s' if today_sessions != 1 else ''} today."
        )
    elif current_streak:
        streak_label = "day" if current_streak == 1 else "days"
        report_summary = f"Focus streak is active at {current_streak} {streak_label}."
    else:
        report_summary = "No completed focus sessions today yet."

    return {
        "today_minutes": today_minutes,
        "today_sessions": today_sessions,
        "week_minutes": week_minutes,
        "week_sessions": week_sessions,
        "completed_sessions": completed_sessions,
        "current_streak_days": current_streak,
        "longest_streak_days": longest_streak,
        "average_session_minutes": average_session_minutes,
        "report_summary": report_summary,
    }
