from datetime import datetime, timezone, date
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.models.task import Task
from app.models.prayer import PrayerLog
from app.models.scheduling import ScheduleBlock
from app.repositories.settings_repository import get_settings_by_user_id
from app.repositories.scheduling_repository import (
    get_daily_schedule_with_blocks,
    get_or_create_daily_schedule,
)
from app.schemas.hasae import HasaeDailyPlanRequest, HasaeDailyPlanResponse
from app.services.hasae_engine import (
    rank_tasks,
    detect_overload,
    get_next_best_action,
    get_replan_candidates,
    score_task,
    generate_daily_smart_plan,
)

router = APIRouter(prefix="/hasae", tags=["H-ASAE"])
HASAE_EXPLANATION_PREFIX = "[H-ASAE]"


async def _get_tasks_data(db: AsyncSession, user_id) -> tuple[list[dict], set[str]]:
    result = await db.execute(
        select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted == False,
        )
    )
    tasks = result.scalars().all()

    completed_ids = {str(t.id) for t in tasks if t.status == "completed"}

    tasks_data = [
        {
            "id": str(t.id),
            "title": t.title,
            "priority": t.priority,
            "status": t.status,
            "due_at": t.due_at,
            "estimated_minutes": t.estimated_minutes,
            "energy_required": t.energy_required,
            "difficulty_level": t.difficulty_level,
            "schedule_flexibility": t.schedule_flexibility,
            "auto_schedule_enabled": t.auto_schedule_enabled,
            "is_splittable": t.is_splittable,
            "dependency_ids": [],
        }
        for t in tasks
    ]

    return tasks_data, completed_ids


async def _get_prayer_data(
    db: AsyncSession,
    user_id,
    target_date: date,
) -> list[dict]:
    result = await db.execute(
        select(PrayerLog).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date == target_date,
        )
    )
    prayer_logs = result.scalars().all()
    return [
        {
            "prayer_name": p.prayer_name,
            "scheduled_at": p.scheduled_at,
        }
        for p in prayer_logs
    ]


async def _get_existing_protected_blocks(
    db: AsyncSession,
    user_id,
    target_date: date,
) -> list[dict]:
    schedule = await get_daily_schedule_with_blocks(db, user_id, target_date)
    if not schedule:
        return []
    protected = []
    for block in schedule.blocks:
        explanation = block.explanation or ""
        if explanation.startswith(HASAE_EXPLANATION_PREFIX):
            continue
        protected.append({
            "start_time": block.start_time,
            "end_time": block.end_time,
            "title": block.title,
            "block_type": block.block_type,
        })
    return protected


async def _build_daily_plan(
    db: AsyncSession,
    user_id,
    target_date: date,
) -> dict:
    tasks_data, completed_ids = await _get_tasks_data(db, user_id)
    prayers_data = await _get_prayer_data(db, user_id, target_date)
    settings = await get_settings_by_user_id(db, user_id)
    protected_blocks = await _get_existing_protected_blocks(
        db,
        user_id,
        target_date,
    )
    return generate_daily_smart_plan(
        tasks=tasks_data,
        prayer_times=prayers_data,
        target_date=target_date,
        wake_time=settings.wake_time if settings else None,
        sleep_time=settings.sleep_time if settings else None,
        completed_task_ids=completed_ids,
        existing_blocks=protected_blocks,
    )


def _response_from_plan(plan: dict) -> HasaeDailyPlanResponse:
    return HasaeDailyPlanResponse(**plan)


async def _persist_plan(
    db: AsyncSession,
    user_id,
    target_date: date,
    plan: dict,
) -> dict:
    schedule = await get_or_create_daily_schedule(db, user_id, target_date)
    schedule = await get_daily_schedule_with_blocks(db, user_id, target_date) or schedule

    for block in list(schedule.blocks):
        if (block.explanation or "").startswith(HASAE_EXPLANATION_PREFIX):
            await db.delete(block)

    saved_blocks = []
    for block in plan["blocks"]:
        task_id = block.get("task_id")
        saved = ScheduleBlock(
            schedule_id=schedule.id,
            user_id=user_id,
            task_id=uuid.UUID(str(task_id)) if task_id else None,
            block_type=block["block_type"],
            title=block["title"],
            start_time=block["start_time"],
            end_time=block["end_time"],
            is_locked=block.get("is_locked", False),
            explanation=block.get("explanation"),
        )
        db.add(saved)
        saved_blocks.append(saved)

    schedule.is_overloaded = plan["overload_warning"]
    schedule.overload_message = plan["overload_message"]
    schedule.total_scheduled_minutes = plan["scheduled_task_minutes"]
    await db.commit()

    for block, saved in zip(plan["blocks"], saved_blocks):
        await db.refresh(saved)
        block["id"] = saved.id
    plan["persisted"] = True
    plan["requires_confirmation"] = False
    return plan


@router.get("/score/{task_id}")
async def get_task_score(
    task_id: str,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the H-ASAE execution score for a specific task."""
    from uuid import UUID
    tasks_data, completed_ids = await _get_tasks_data(db, current_user.id)
    task = next((t for t in tasks_data if t["id"] == task_id), None)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    now = datetime.now(timezone.utc)
    return score_task(task, now, 480)


@router.get("/rank")
async def rank_all_tasks(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rank all pending tasks by H-ASAE score."""
    tasks_data, completed_ids = await _get_tasks_data(db, current_user.id)
    now = datetime.now(timezone.utc)
    ranked = rank_tasks(tasks_data, now, 480, completed_ids)
    return {
        "ranked_at": now.isoformat(),
        "total_eligible": len(ranked),
        "tasks": ranked,
    }


@router.post("/daily-plan", response_model=HasaeDailyPlanResponse)
async def generate_daily_plan_preview(
    payload: HasaeDailyPlanRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Generate a H-ASAE daily smart plan preview.

    The endpoint does not write schedule blocks. The user must explicitly
    confirm the preview through /hasae/daily-plan/accept.
    """
    target_date = payload.date or date.today()
    plan = await _build_daily_plan(db, current_user.id, target_date)
    return _response_from_plan(plan)


@router.post("/daily-plan/accept", response_model=HasaeDailyPlanResponse)
async def accept_daily_plan(
    payload: HasaeDailyPlanRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Persist the generated H-ASAE daily plan after user confirmation.

    Existing H-ASAE-generated blocks for the same date are replaced, while
    manually created non-H-ASAE blocks remain protected.
    """
    target_date = payload.date or date.today()
    plan = await _build_daily_plan(db, current_user.id, target_date)
    saved_plan = await _persist_plan(db, current_user.id, target_date, plan)
    return _response_from_plan(saved_plan)


@router.get("/overload")
async def check_overload(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Detect if today's workload exceeds healthy capacity."""
    tasks_data, _ = await _get_tasks_data(db, current_user.id)
    result = detect_overload(tasks_data)
    return result


@router.get("/next-action")
async def deterministic_next_action(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the best next action using H-ASAE deterministic scoring.
    Respects prayer times as hard constraints.
    """
    tasks_data, completed_ids = await _get_tasks_data(db, current_user.id)

    # Get today's prayer times
    today = date.today()
    prayers_result = await db.execute(
        select(PrayerLog).where(
            PrayerLog.user_id == current_user.id,
            PrayerLog.prayer_date == today,
            PrayerLog.completed == False,
        )
    )
    prayer_logs = prayers_result.scalars().all()
    prayers_data = [
        {
            "prayer_name": p.prayer_name,
            "scheduled_at": p.scheduled_at.isoformat() if p.scheduled_at else None,
        }
        for p in prayer_logs
    ]

    now = datetime.now(timezone.utc)
    result = get_next_best_action(tasks_data, prayers_data, now, completed_ids)
    return result


@router.get("/replan")
async def trigger_replan(
    event: str = Query(
        default="task_completed",
        description="Automation trigger event",
    ),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Identify replanning candidates after an automation event.
    Only affects future schedule — never touches past blocks.
    """
    valid_events = [
        "task_completed",
        "task_skipped",
        "day_overloaded",
        "dependency_unlocked",
        "prayer_schedule_changed",
        "user_routine_changed",
    ]
    if event not in valid_events:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid event. Must be one of: {valid_events}",
        )

    tasks_data, completed_ids = await _get_tasks_data(db, current_user.id)
    now = datetime.now(timezone.utc)
    result = get_replan_candidates(tasks_data, now, completed_ids, event)
    return result
