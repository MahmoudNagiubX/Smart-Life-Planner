from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user
from app.core.dependencies import get_db
from app.repositories.context_repository import (
    create_context_snapshot,
    get_latest_context_snapshot,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.schemas.context import (
    ContextSnapshotCreate,
    ContextSnapshotResponse,
    TimeContextRecommendationResponse,
)
from app.services.context_recommendations import (
    VALID_TIME_BLOCKS,
    build_time_context_recommendations,
)
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


@router.get("/recommendations", response_model=TimeContextRecommendationResponse)
async def get_time_context_recommendations(
    time_block: str | None = Query(default=None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await get_settings_by_user_id(db, current_user.id)
    snapshot = await get_latest_context_snapshot(db, current_user.id)
    selected_block = time_block or (snapshot.local_time_block if snapshot else None)
    if selected_block not in VALID_TIME_BLOCKS:
        timezone_name = safe_timezone_name(settings.timezone if settings else "UTC")
        selected_block = classify_local_time_block(local_now(timezone_name))
    energy_level = (snapshot.energy_level if snapshot else None) or "medium"
    goals = settings.goals if settings else []
    recommendations = build_time_context_recommendations(
        local_time_block=selected_block,
        energy_level=energy_level,
        goals=goals,
    )
    return TimeContextRecommendationResponse(
        local_time_block=selected_block,
        energy_level=energy_level,
        goal_tags=goals,
        recommendations=recommendations,
        explanation=(
            f"{selected_block.title()} recommendations use your current "
            f"{energy_level} energy level and saved goals."
        ),
    )


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
