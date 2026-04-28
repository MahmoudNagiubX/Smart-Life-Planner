from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.prayer import (
    DailyPrayerResponse,
    PrayerResponse,
    PrayerLogResponse,
    QuranGoalSummaryResponse,
    QuranGoalUpsert,
    QuranProgressUpdate,
    QuranWeeklyProgressItem,
)
from app.repositories.prayer_repository import (
    get_prayer_logs_for_date,
    get_prayer_log,
    upsert_prayer_log,
    mark_prayer_complete,
    mark_prayer_incomplete,
    get_prayer_history,
    get_quran_goal,
    delete_quran_goal,
    get_quran_progress_for_date,
    get_quran_progress_range,
    upsert_quran_goal,
    upsert_quran_progress,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.services.prayer_calculator import calculate_prayer_times, PRAYER_NAMES

router = APIRouter(prefix="/prayers", tags=["prayers"])

DEFAULT_LAT = 30.0444
DEFAULT_LNG = 31.2357


async def _build_quran_goal_summary(
    db: AsyncSession,
    user_id,
) -> QuranGoalSummaryResponse:
    today = date.today()
    week_start = today - timedelta(days=6)
    goal = await get_quran_goal(db, user_id)
    today_progress = await get_quran_progress_for_date(db, user_id, today)
    week_progress = await get_quran_progress_range(db, user_id, week_start, today)

    progress_by_date = {item.progress_date: item for item in week_progress}
    target = goal.daily_page_target if goal else 0
    today_pages = today_progress.pages_completed if today_progress else 0
    weekly_total = sum(item.pages_completed for item in week_progress)

    weekly_summary = []
    for offset in range(7):
        current_date = week_start + timedelta(days=offset)
        progress = progress_by_date.get(current_date)
        pages_completed = progress.pages_completed if progress else 0
        weekly_summary.append(
            QuranWeeklyProgressItem(
                progress_date=current_date,
                pages_completed=pages_completed,
                target_met=target > 0 and pages_completed >= target,
            )
        )

    return QuranGoalSummaryResponse(
        goal=goal,
        today=today_progress,
        today_pages_completed=today_pages,
        progress_percent=0
        if target == 0
        else min(100, int(today_pages / target * 100)),
        weekly_total_pages=weekly_total,
        weekly_target_pages=target * 7,
        weekly_summary=weekly_summary,
    )


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


@router.get("/quran-goal", response_model=QuranGoalSummaryResponse)
async def get_quran_goal_summary(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _build_quran_goal_summary(db, current_user.id)


@router.put("/quran-goal", response_model=QuranGoalSummaryResponse)
async def upsert_user_quran_goal(
    payload: QuranGoalUpsert,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await upsert_quran_goal(db, current_user.id, payload.daily_page_target)
    return await _build_quran_goal_summary(db, current_user.id)


@router.delete("/quran-goal", status_code=status.HTTP_204_NO_CONTENT)
async def disable_user_quran_goal(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await delete_quran_goal(db, current_user.id)


@router.put("/quran-progress/today", response_model=QuranGoalSummaryResponse)
async def update_today_quran_progress(
    payload: QuranProgressUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await upsert_quran_progress(
        db,
        current_user.id,
        date.today(),
        payload.pages_completed,
    )
    return await _build_quran_goal_summary(db, current_user.id)


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
