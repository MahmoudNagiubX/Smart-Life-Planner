import uuid
from datetime import datetime, timezone

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.context import ContextSnapshot


async def get_latest_context_snapshot(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> ContextSnapshot | None:
    result = await db.execute(
        select(ContextSnapshot)
        .where(ContextSnapshot.user_id == user_id)
        .order_by(desc(ContextSnapshot.timestamp))
        .limit(1)
    )
    return result.scalar_one_or_none()


async def create_context_snapshot(
    db: AsyncSession,
    user_id: uuid.UUID,
    *,
    timezone_name: str,
    local_time_block: str,
    energy_level: str | None,
    coarse_location_context: str | None,
    weather_summary: str | None,
    device_context: str | None,
) -> ContextSnapshot:
    snapshot = ContextSnapshot(
        user_id=user_id,
        timestamp=datetime.now(timezone.utc),
        timezone=timezone_name,
        local_time_block=local_time_block,
        energy_level=energy_level,
        coarse_location_context=coarse_location_context,
        weather_summary=weather_summary,
        device_context=device_context,
    )
    db.add(snapshot)
    await db.commit()
    await db.refresh(snapshot)
    return snapshot
