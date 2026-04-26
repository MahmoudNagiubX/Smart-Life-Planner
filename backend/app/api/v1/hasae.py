from datetime import datetime, timezone, date
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.models.task import Task
from app.models.prayer import PrayerLog
from app.services.hasae_engine import (
    rank_tasks,
    detect_overload,
    get_next_best_action,
    get_replan_candidates,
    score_task,
)

router = APIRouter(prefix="/hasae", tags=["H-ASAE"])


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