from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.prayer import DailyPrayerResponse, PrayerResponse, PrayerLogResponse
from app.repositories.prayer_repository import (
    get_prayer_logs_for_date,
    get_prayer_log,
    upsert_prayer_log,
    mark_prayer_complete,
    mark_prayer_incomplete,
    get_prayer_history,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.services.prayer_calculator import calculate_prayer_times, PRAYER_NAMES

router = APIRouter(prefix="/prayers", tags=["prayers"])

DEFAULT_LAT = 30.0444
DEFAULT_LNG = 31.2357


@router.get("/today", response_model=DailyPrayerResponse)
async def get_today_prayers(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    settings = await get_settings_by_user_id(db, current_user.id)

    lat = settings.prayer_location_lat if settings else DEFAULT_LAT
    lng = settings.prayer_location_lng if settings else DEFAULT_LNG
    method = settings.prayer_calculation_method if settings else "MWL"

    lat = lat or DEFAULT_LAT
    lng = lng or DEFAULT_LNG

    try:
        times = calculate_prayer_times(lat, lng, today, method)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not calculate prayer times",
        )

    prayers_response = []
    completed_count = 0

    for name in PRAYER_NAMES:
        scheduled_at = times.get(name)
        log = await upsert_prayer_log(db, current_user.id, name, today, scheduled_at)
        if log.completed:
            completed_count += 1
        prayers_response.append(
            PrayerResponse(
                prayer_name=name,
                scheduled_at=log.scheduled_at,
                completed=log.completed,
                completed_at=log.completed_at,
            )
        )

    return DailyPrayerResponse(
        date=today.isoformat(),
        prayers=prayers_response,
        completed_count=completed_count,
        total_count=len(PRAYER_NAMES),
    )


@router.patch("/{prayer_name}/{prayer_date}/complete", response_model=PrayerLogResponse)
async def complete_prayer(
    prayer_name: str,
    prayer_date: date,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if prayer_name not in PRAYER_NAMES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid prayer name. Must be one of {PRAYER_NAMES}",
        )
    log = await get_prayer_log(db, current_user.id, prayer_name, prayer_date)
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prayer log not found. Call /today first to generate logs.",
        )
    return await mark_prayer_complete(db, log)


@router.patch("/{prayer_name}/{prayer_date}/uncomplete", response_model=PrayerLogResponse)
async def uncomplete_prayer(
    prayer_name: str,
    prayer_date: date,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if prayer_name not in PRAYER_NAMES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid prayer name. Must be one of {PRAYER_NAMES}",
        )
    log = await get_prayer_log(db, current_user.id, prayer_name, prayer_date)
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prayer log not found",
        )
    return await mark_prayer_incomplete(db, log)


@router.get("/history", response_model=list[PrayerLogResponse])
async def prayer_history(
    date_from: date = Query(default=None),
    date_to: date = Query(default=None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    date_from = date_from or (today - timedelta(days=7))
    date_to = date_to or today
    return await get_prayer_history(db, current_user.id, date_from, date_to)