import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import case, select, func
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.repositories.settings_repository import get_settings_by_user_id
from app.models.habit import Habit, HabitLog
from app.models.task import Task
from app.models.prayer import PrayerLog

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

GOAL_LABELS = {
    "study": "Study",
    "work": "Work",
    "self_improvement": "Self Improvement",
    "fitness": "Fitness",
    "spiritual_growth": "Spiritual Growth",
}


def _goal_label(goal: str) -> str:
    return GOAL_LABELS.get(goal, goal.replace("_", " ").title())


def _task_environment(goals: list[str]) -> str:
    if "study" in goals and "spiritual_growth" in goals:
        return "Study-focused day with prayer-aware planning"
    if "study" in goals:
        return "Study-focused planning"
    if "work" in goals:
        return "Deep work planning"
    if "fitness" in goals:
        return "Energy and wellness planning"
    if "spiritual_growth" in goals:
        return "Prayer-aware daily planning"
    return "Balanced daily planning"


def _journal_prompt(goals: list[str]) -> str:
    if "spiritual_growth" in goals:
        return "What helped you stay mindful and consistent today?"
    if "study" in goals:
        return "What did you learn today, and what needs review?"
    if "fitness" in goals:
        return "How did your energy feel today?"
    if "work" in goals:
        return "What moved your most important work forward today?"
    return "What is one thing worth remembering from today?"


def _ai_plan_preview(goals: list[str], wake_time: str | None, sleep_time: str | None) -> str:
    rhythm = []
    if wake_time:
        rhythm.append(f"start after {wake_time}")
    if sleep_time:
        rhythm.append(f"wind down before {sleep_time}")
    rhythm_text = ", ".join(rhythm) if rhythm else "use your daily rhythm"

    if "study" in goals and "spiritual_growth" in goals:
        return f"Plan study blocks around prayer anchors and {rhythm_text}."
    if goals:
        return f"Prioritize {', '.join(_goal_label(g) for g in goals[:2])} and {rhythm_text}."
    return f"Build a balanced plan and {rhythm_text}."


@router.get("/home")
async def get_home_dashboard(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id: uuid.UUID = current_user.id
    now = datetime.now(timezone.utc)
    today = now.date()
    settings = await get_settings_by_user_id(db, user_id)
    goals = settings.goals if settings else []

    # Pending tasks count
    pending_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.is_deleted == False,
        )
    )
    pending_count = pending_result.scalar() or 0

    # Completed today count
    completed_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "completed",
            Task.is_deleted == False,
            func.date(Task.completed_at) == today,
        )
    )
    completed_today = completed_result.scalar() or 0

    # Top 5 pending tasks
    top_tasks_result = await db.execute(
        select(Task)
        .where(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.is_deleted == False,
        )
        .order_by(Task.due_at.asc().nulls_last(), Task.created_at.asc())
        .limit(5)
    )
    top_tasks = top_tasks_result.scalars().all()

    # Today's prayer progress
    prayers_result = await db.execute(
        select(
            func.count(PrayerLog.id),
            func.sum(
                case((PrayerLog.completed == True, 1), else_=0)
            ),
        ).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date == today,
        )
    )
    prayer_row = prayers_result.one()
    total_prayers = prayer_row[0] or 0
    completed_prayers = prayer_row[1] or 0

    next_prayer_result = await db.execute(
        select(PrayerLog)
        .where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date == today,
            PrayerLog.scheduled_at.is_not(None),
            PrayerLog.scheduled_at >= now,
        )
        .order_by(PrayerLog.scheduled_at.asc())
        .limit(1)
    )
    next_prayer = next_prayer_result.scalar_one_or_none()

    habit_count_result = await db.execute(
        select(func.count(Habit.id)).where(
            Habit.user_id == user_id,
            Habit.is_deleted == False,
            Habit.is_active == True,
        )
    )
    active_habits = habit_count_result.scalar() or 0

    completed_habits_result = await db.execute(
        select(func.count(HabitLog.id)).where(
            HabitLog.user_id == user_id,
            HabitLog.log_date == today,
            HabitLog.is_completed == True,
        )
    )
    completed_habits = completed_habits_result.scalar() or 0

    return {
        "pending_count": pending_count,
        "completed_today": completed_today,
        "prayer_progress": {
            "completed": completed_prayers,
            "total": total_prayers if total_prayers > 0 else 5,
        },
        "top_tasks": [
            {
                "id": str(t.id),
                "title": t.title,
                "priority": t.priority,
                "due_at": t.due_at.isoformat() if t.due_at else None,
                "status": t.status,
            }
            for t in top_tasks
        ],
        "personalization": {
            "goal_tags": goals,
            "goal_labels": [_goal_label(goal) for goal in goals],
            "task_environment": _task_environment(goals),
            "daily_dashboard_widgets": [
                "top_tasks",
                "next_prayer",
                "habit_snapshot",
                "journal_prompt",
                "ai_plan",
                "focus_shortcut",
            ],
            "next_prayer": {
                "name": next_prayer.prayer_name if next_prayer else None,
                "scheduled_at": next_prayer.scheduled_at.isoformat()
                if next_prayer and next_prayer.scheduled_at
                else None,
                "enabled": "spiritual_growth" in goals,
            },
            "habit_snapshot": {
                "active_count": active_habits,
                "completed_today": completed_habits,
                "highlight": "Daily habits are ready"
                if active_habits
                else "Default habits will appear after setup",
            },
            "journal_prompt": _journal_prompt(goals),
            "ai_plan_card": {
                "title": "Personalized plan",
                "preview": _ai_plan_preview(
                    goals,
                    settings.wake_time if settings else None,
                    settings.sleep_time if settings else None,
                ),
            },
            "focus_shortcut": {
                "label": "Start focus",
                "suggested_minutes": 45 if "study" in goals or "work" in goals else 25,
            },
        },
    }
