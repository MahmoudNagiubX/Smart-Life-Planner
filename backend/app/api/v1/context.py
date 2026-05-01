from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user
from app.core.dependencies import get_db
from app.repositories.context_repository import (
    create_context_snapshot,
    get_latest_context_snapshot,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.schemas.context import ContextSnapshotCreate, ContextSnapshotResponse
from app.services.context_snapshot import (
    classify_local_time_block,
    local_now,
    safe_timezone_name,
)

router = APIRouter(prefix="/context", tags=["context"])


@router.get("/snapshot", response_model=ContextSnapshotResponse)
async def get_context_snapshot(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    snapshot = await get_latest_context_snapshot(db, current_user.id)
    if snapshot:
        return snapshot
    return await _create_snapshot_from_payload(
        db,
        current_user.id,
        ContextSnapshotCreate(),
    )


@router.post("/snapshot", response_model=ContextSnapshotResponse)
async def create_user_context_snapshot(
    payload: ContextSnapshotCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _create_snapshot_from_payload(db, current_user.id, payload)


async def _create_snapshot_from_payload(
    db: AsyncSession,
    user_id,
    payload: ContextSnapshotCreate,
):
    settings = await get_settings_by_user_id(db, user_id)
    timezone_name = safe_timezone_name(
        payload.timezone or (settings.timezone if settings else "UTC")
    )
    location_context = payload.coarse_location_context
    if location_context is None and settings:
        city = settings.city or ""
        country = settings.country or ""
        location_context = ", ".join(part for part in [city, country] if part) or None
    now_local = local_now(timezone_name, datetime.now(timezone.utc))
    return await create_context_snapshot(
        db,
        user_id,
        timezone_name=timezone_name,
        local_time_block=classify_local_time_block(now_local),
        energy_level=payload.energy_level,
        coarse_location_context=location_context,
        weather_summary=payload.weather_summary,
        device_context=payload.device_context,
    )
