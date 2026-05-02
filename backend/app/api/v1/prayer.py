from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.prayer import (
    DailyPrayerResponse,
    PrayerResponse,
    PrayerLogResponse,
    PrayerStatusUpdate,
    PrayerWeeklySummaryResponse,
    QuranGoalSummaryResponse,
    QuranGoalUpsert,
    QuranProgressUpdate,
    QuranWeeklyProgressItem,
    RamadanDailySummaryResponse,
    RamadanFastingLogUpdate,
    HijriDateResponse,
    IslamicCalendarResponse,
    IslamicCalendarEventResponse,
)
from app.repositories.prayer_repository import (
    get_prayer_logs_for_date,
    upsert_prayer_log,
    mark_prayer_complete,
    mark_prayer_incomplete,
    mark_prayer_status,
    get_prayer_history,
    get_prayer_weekly_summary,
    get_quran_goal,
    delete_quran_goal,
    get_quran_progress_for_date,
    get_quran_progress_range,
    upsert_quran_goal,
    upsert_quran_progress,
    get_ramadan_fasting_log,
    get_ramadan_fasting_logs_for_month,
    upsert_ramadan_fasting_log,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.services.prayer_calculator import calculate_prayer_times, PRAYER_NAMES
from app.services.islamic_calendar import (
    gregorian_to_hijri,
    upcoming_islamic_events,
)
from app.services.quran_summary import (
    quran_completion_percent,
    quran_current_streak,
)

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
        target_pages = (progress.target_pages if progress else 0) or target
        weekly_summary.append(
            QuranWeeklyProgressItem(
                progress_date=current_date,
                pages_completed=pages_completed,
                target_pages=target_pages,
                target_met=target_pages > 0 and pages_completed >= target_pages,
                completion_percent=quran_completion_percent(
                    pages_completed,
                    target_pages,
                ),
            )
        )
    weekly_target = sum(item.target_pages for item in weekly_summary)

    return QuranGoalSummaryResponse(
        goal=goal,
        today=today_progress,
        today_pages_completed=today_pages,
        progress_percent=quran_completion_percent(today_pages, target),
        weekly_total_pages=weekly_total,
        weekly_target_pages=weekly_target,
        weekly_completion_percent=quran_completion_percent(
            weekly_total,
            weekly_target,
        ),
        current_streak_days=quran_current_streak(weekly_summary),
        weekly_summary=weekly_summary,
    )


async def _active_quran_target(db: AsyncSession, user_id) -> int:
    goal = await get_quran_goal(db, user_id)
    return goal.daily_page_target if goal else 0


async def _build_ramadan_daily_summary(
    db: AsyncSession,
    user_id,
    target_date: date,
) -> RamadanDailySummaryResponse:
    today_log = await get_ramadan_fasting_log(db, user_id, target_date)
    month_logs = await get_ramadan_fasting_logs_for_month(
        db,
        user_id,
        target_date.year,
        target_date.month,
    )
    fasted_count = sum(1 for log in month_logs if log.fasted)
    not_fasted_count = sum(1 for log in month_logs if not log.fasted)
    return RamadanDailySummaryResponse(
        date=target_date,
        today=today_log,
        month=target_date.month,
        year=target_date.year,
        month_fasted_count=fasted_count,
        month_not_fasted_count=not_fasted_count,
        month_logged_count=len(month_logs),
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
    missed_count = 0

    for name in PRAYER_NAMES:
        scheduled_at = times.get(name)
        log = await upsert_prayer_log(db, current_user.id, name, today, scheduled_at)
        if log.completed:
            completed_count += 1
        if log.status == "missed":
            missed_count += 1
        prayers_response.append(
            PrayerResponse(
                prayer_name=name,
                scheduled_at=log.scheduled_at,
                completed=log.completed,
                completed_at=log.completed_at,
                status=log.status,
            )
        )

    return DailyPrayerResponse(
        date=today.isoformat(),
        prayers=prayers_response,
        completed_count=completed_count,
        total_count=len(PRAYER_NAMES),
        missed_count=missed_count,
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
    target_pages = await _active_quran_target(db, current_user.id)
    await upsert_quran_progress(
        db,
        current_user.id,
        date.today(),
        payload.pages_completed,
        target_pages,
    )
    return await _build_quran_goal_summary(db, current_user.id)


@router.put(
    "/quran-progress/{progress_date}",
    response_model=QuranGoalSummaryResponse,
)
async def update_quran_progress_for_date(
    progress_date: date,
    payload: QuranProgressUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if progress_date > date.today():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quran progress cannot be logged for a future date",
        )
    target_pages = await _active_quran_target(db, current_user.id)
    await upsert_quran_progress(
        db,
        current_user.id,
        progress_date,
        payload.pages_completed,
        target_pages,
    )
    return await _build_quran_goal_summary(db, current_user.id)


@router.get("/ramadan/fasting/today", response_model=RamadanDailySummaryResponse)
async def get_today_ramadan_fasting_summary(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _build_ramadan_daily_summary(db, current_user.id, date.today())


@router.put("/ramadan/fasting/today", response_model=RamadanDailySummaryResponse)
async def update_today_ramadan_fasting_log(
    payload: RamadanFastingLogUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    await upsert_ramadan_fasting_log(
        db,
        current_user.id,
        today,
        payload.fasted,
        payload.note.strip() if payload.note else None,
        payload.fast_type,
        payload.makeup_for_date,
    )
    return await _build_ramadan_daily_summary(db, current_user.id, today)


@router.get("/islamic-calendar", response_model=IslamicCalendarResponse)
async def get_islamic_calendar(
    target_date: date | None = Query(default=None),
    current_user=Depends(get_current_user),
):
    selected_date = target_date or date.today()
    hijri = gregorian_to_hijri(selected_date)
    events = upcoming_islamic_events(selected_date)
    return IslamicCalendarResponse(
        gregorian_date=selected_date,
        hijri_date=HijriDateResponse(
            year=hijri.year,
            month=hijri.month,
            day=hijri.day,
            month_name=hijri.month_name,
            label=hijri.label,
            estimated=True,
        ),
        events=[
            IslamicCalendarEventResponse(
                key=event.key,
                title=event.title,
                hijri_month=event.hijri_month,
                hijri_day=event.hijri_day,
                gregorian_date=event.gregorian_date,
                hijri_label=event.hijri_label,
                estimated=event.estimated,
                description=event.description,
            )
            for event in events
        ],
        calculation_note=(
            "Dates are estimated using a civil Hijri calculation and may differ "
            "from local moon-sighting announcements."
        ),
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
    log = await upsert_prayer_log(
        db,
        current_user.id,
        prayer_name,
        prayer_date,
        scheduled_at=None,
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
    log = await upsert_prayer_log(
        db,
        current_user.id,
        prayer_name,
        prayer_date,
        scheduled_at=None,
    )
    return await mark_prayer_incomplete(db, log)


@router.patch("/{prayer_name}/{prayer_date}/status", response_model=PrayerLogResponse)
async def update_prayer_status(
    prayer_name: str,
    prayer_date: date,
    payload: PrayerStatusUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if prayer_name not in PRAYER_NAMES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid prayer name. Must be one of {PRAYER_NAMES}",
        )
    log = await upsert_prayer_log(
        db,
        current_user.id,
        prayer_name,
        prayer_date,
        scheduled_at=None,
    )
    try:
        return await mark_prayer_status(db, log, payload.status)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


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


@router.get("/history/weekly", response_model=PrayerWeeklySummaryResponse)
async def weekly_prayer_history_summary(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    # Go back 6 days to get a 7-day window ending today
    week_start = today - timedelta(days=6)
    return await get_prayer_weekly_summary(db, current_user.id, week_start, today)
