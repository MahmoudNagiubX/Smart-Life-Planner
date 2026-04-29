import uuid
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import case, select, func
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.repositories.settings_repository import get_settings_by_user_id
from app.schemas.settings import DEFAULT_DASHBOARD_WIDGETS, validate_dashboard_widgets
from app.models.habit import Habit, HabitLog
from app.models.task import Task
from app.models.prayer import PrayerLog, QuranGoal, QuranProgress, RamadanFastingLog
from app.services.prayer_calculator import PRAYER_NAMES, calculate_prayer_times
from app.services.quran_summary import quran_completion_percent

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

DEFAULT_LAT = 30.0444
DEFAULT_LNG = 31.2357

GOAL_LABELS = {
    "study": "Study",
    "work": "Work",
    "self_improvement": "Self Improvement",
    "fitness": "Fitness",
    "spiritual_growth": "Spiritual Growth",
}


def _dashboard_widgets(raw_widgets: list[str] | None) -> list[str]:
    if raw_widgets is None:
        return DEFAULT_DASHBOARD_WIDGETS
    return validate_dashboard_widgets(raw_widgets) or []


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


def _normalized_prayer_time(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _calculate_next_prayer(settings, now: datetime) -> dict[str, str | None]:
    lat = settings.prayer_location_lat if settings else DEFAULT_LAT
    lng = settings.prayer_location_lng if settings else DEFAULT_LNG
    method = settings.prayer_calculation_method if settings else "MWL"
    lat = lat or DEFAULT_LAT
    lng = lng or DEFAULT_LNG

    for day_offset in (0, 1):
        prayer_date = now.date() + timedelta(days=day_offset)
        try:
            times = calculate_prayer_times(lat, lng, prayer_date, method)
        except Exception:
            return {"name": None, "scheduled_at": None}
        for prayer_name in PRAYER_NAMES:
            scheduled_at = _normalized_prayer_time(times.get(prayer_name))
            if scheduled_at is not None and scheduled_at >= now:
                return {
                    "name": prayer_name,
                    "scheduled_at": scheduled_at.isoformat(),
                }
    return {"name": None, "scheduled_at": None}


def _ramadan_dashboard_label(enabled: bool, log: RamadanFastingLog | None) -> str:
    if not enabled:
        return "Ramadan mode is off"
    if log is None:
        return "Ramadan mode on - fasting not logged yet"
    return "Fasting logged today" if log.fasted else "Today marked not fasting"


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

    next_prayer = _calculate_next_prayer(settings, now)

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

    quran_goal_result = await db.execute(
        select(QuranGoal).where(QuranGoal.user_id == user_id)
    )
    quran_goal = quran_goal_result.scalar_one_or_none()
    quran_progress_result = await db.execute(
        select(QuranProgress).where(
            QuranProgress.user_id == user_id,
            QuranProgress.progress_date == today,
        )
    )
    quran_progress = quran_progress_result.scalar_one_or_none()
    quran_daily_target = quran_goal.daily_page_target if quran_goal else 0
    quran_pages_today = quran_progress.pages_completed if quran_progress else 0

    ramadan_enabled = bool(settings and settings.ramadan_mode_enabled)
    ramadan_log = None
    if ramadan_enabled:
        ramadan_result = await db.execute(
            select(RamadanFastingLog).where(
                RamadanFastingLog.user_id == user_id,
                RamadanFastingLog.fasting_date == today,
            )
        )
        ramadan_log = ramadan_result.scalar_one_or_none()

    prayer_progress = {
        "completed": completed_prayers,
        "total": total_prayers if total_prayers > 0 else len(PRAYER_NAMES),
    }
    quran_dashboard = {
        "enabled": quran_goal is not None,
        "daily_page_target": quran_daily_target,
        "today_pages_completed": quran_pages_today,
        "progress_percent": quran_completion_percent(
            quran_pages_today,
            quran_daily_target,
        ),
    }
    ramadan_dashboard = {
        "enabled": ramadan_enabled,
        "today_logged": ramadan_log is not None,
        "fasted": ramadan_log.fasted if ramadan_log else None,
        "label": _ramadan_dashboard_label(ramadan_enabled, ramadan_log),
    }

    return {
        "pending_count": pending_count,
        "completed_today": completed_today,
        "prayer_progress": prayer_progress,
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
            "daily_dashboard_widgets": _dashboard_widgets(
                settings.dashboard_widgets if settings else None
            ),
            "next_prayer": {
                "name": next_prayer["name"],
                "scheduled_at": next_prayer["scheduled_at"],
                "enabled": "spiritual_growth" in goals,
            },
            "spiritual_summary": {
                "next_prayer": {
                    "name": next_prayer["name"],
                    "scheduled_at": next_prayer["scheduled_at"],
                    "enabled": True,
                },
                "prayer_progress": prayer_progress,
                "quran_goal": quran_dashboard,
                "ramadan": ramadan_dashboard,
                "qibla": {
                    "available": bool(
                        settings
                        and settings.prayer_location_lat is not None
                        and settings.prayer_location_lng is not None
                    ),
                    "label": "Open Qibla direction",
                },
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
