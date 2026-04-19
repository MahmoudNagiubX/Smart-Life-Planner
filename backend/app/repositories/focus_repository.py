import uuid
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.focus import FocusSession


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
    await db.commit()
    await db.refresh(session)
    return session


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

    return {
        "today_minutes": today_minutes,
        "today_sessions": today_sessions,
        "week_minutes": week_minutes,
        "week_sessions": week_sessions,
    }