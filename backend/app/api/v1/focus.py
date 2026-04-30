import uuid
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.models.focus import FocusSession
from app.models.task import Task
from app.schemas.focus import (
    FocusAnalyticsResponse,
    FocusReadinessResponse,
    FocusRecommendationResponse,
    FocusSettingsResponse,
    FocusSettingsUpdate,
    FocusSessionCreate,
    FocusSessionResponse,
)
from app.core.config import settings
from app.repositories.focus_repository import (
    cancel_session,
    complete_session,
    create_session,
    get_active_session,
    get_focus_analytics,
    get_focus_settings,
    get_session_by_id,
    get_sessions,
    update_focus_settings,
)
from app.repositories.task_repository import get_task_by_id, get_tasks
from app.services.ai_service import explain_focus_recommendation
from app.services.focus_recommendation import (
    apply_ai_focus_explanation,
    build_focus_recommendation,
)
from app.services.hasae_engine import detect_overload
from app.services.productivity_prediction import predict_focus_readiness

router = APIRouter(prefix="/focus", tags=["focus"])


@router.get("/settings", response_model=FocusSettingsResponse)
async def get_settings(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await get_focus_settings(db, current_user.id)
    if not settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Focus settings not found",
        )
    return settings


@router.patch("/settings", response_model=FocusSettingsResponse)
async def update_settings(
    payload: FocusSettingsUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await update_focus_settings(
        db,
        current_user.id,
        payload.model_dump(exclude_none=True),
    )
    if not settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Focus settings not found",
        )
    return settings


@router.post(
    "/sessions",
    response_model=FocusSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def start_session(
    payload: FocusSessionCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await get_active_session(db, current_user.id)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You already have an active focus session",
        )
    if payload.task_id:
        task = await get_task_by_id(db, payload.task_id, current_user.id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found",
            )
    return await create_session(db, current_user.id, payload.model_dump())


@router.get("/sessions", response_model=list[FocusSessionResponse])
async def list_sessions(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_sessions(db, current_user.id)


@router.get("/sessions/active", response_model=FocusSessionResponse)
async def get_active(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_active_session(db, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active session",
        )
    return session


@router.patch(
    "/sessions/{session_id}/complete",
    response_model=FocusSessionResponse,
)
async def finish_session(
    session_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_session_by_id(db, session_id, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )
    return await complete_session(db, session)


@router.patch(
    "/sessions/{session_id}/cancel",
    response_model=FocusSessionResponse,
)
async def abort_session(
    session_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_session_by_id(db, session_id, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )
    return await cancel_session(db, session)


@router.get("/analytics", response_model=FocusAnalyticsResponse)
async def focus_analytics(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_focus_analytics(db, current_user.id)


@router.get("/recommendation", response_model=FocusRecommendationResponse)
async def focus_recommendation(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    focus_settings = await get_focus_settings(db, current_user.id)
    default_duration = (
        focus_settings.default_focus_minutes if focus_settings else 25
    )
    tasks = await get_tasks(db, current_user.id, status="pending")
    recommendation = build_focus_recommendation(
        tasks,
        default_duration_minutes=default_duration,
    )

    if recommendation["task_id"] and settings.GROQ_API_KEY:
        try:
            explanation = await explain_focus_recommendation(
                recommendation["title"] or "Recommended task",
                recommendation["reasons"],
                recommendation["recommended_duration_minutes"],
            )
            recommendation = apply_ai_focus_explanation(
                recommendation,
                explanation,
            )
        except Exception:
            # The deterministic recommendation remains the source of truth.
            pass

    return recommendation


@router.get("/readiness", response_model=FocusReadinessResponse)
async def focus_readiness(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    now_utc = datetime.now(timezone.utc)
    week_start = now_utc - timedelta(days=6)
    focus_settings = await get_focus_settings(db, current_user.id)
    prediction_now = _prediction_now(
        focus_settings.timezone if focus_settings else None
    )
    focus_analytics = await get_focus_analytics(db, current_user.id)

    completed_tasks_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == current_user.id,
            Task.is_deleted == False,
            Task.status == "completed",
            Task.completed_at.is_not(None),
            Task.completed_at >= week_start,
        )
    )
    completed_tasks = int(completed_tasks_result.scalar() or 0)

    open_tasks_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == current_user.id,
            Task.is_deleted == False,
            Task.status.in_(("pending", "next", "in_progress", "waiting")),
        )
    )
    open_tasks = int(open_tasks_result.scalar() or 0)
    denominator = completed_tasks + open_tasks
    task_completion_rate = (
        round((completed_tasks / denominator) * 100) if denominator else 0
    )

    tasks = await get_tasks(db, current_user.id)
    overload = detect_overload(
        [
            {
                "status": task.status,
                "estimated_minutes": task.estimated_minutes,
            }
            for task in tasks
        ]
    )

    focus_session_count_result = await db.execute(
        select(func.count(FocusSession.id)).where(
            FocusSession.user_id == current_user.id,
            FocusSession.status == "completed",
            FocusSession.started_at >= week_start,
        )
    )
    recent_focus_sessions = int(focus_session_count_result.scalar() or 0)
    if recent_focus_sessions == 0:
        task_completion_rate = min(task_completion_rate, 39)

    return predict_focus_readiness(
        focus_streak_days=int(focus_analytics["current_streak_days"]),
        task_completion_rate_percent=task_completion_rate,
        overload_load_ratio=float(overload.get("load_ratio", 0)),
        wake_time=focus_settings.wake_time if focus_settings else None,
        sleep_time=focus_settings.sleep_time if focus_settings else None,
        now=prediction_now,
    )


def _prediction_now(timezone_name: str | None) -> datetime:
    if not timezone_name:
        return datetime.now(timezone.utc)
    try:
        return datetime.now(ZoneInfo(timezone_name))
    except ZoneInfoNotFoundError:
        return datetime.now(timezone.utc)
