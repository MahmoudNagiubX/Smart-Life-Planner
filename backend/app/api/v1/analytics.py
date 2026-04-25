import uuid
from datetime import datetime, timezone, timedelta, date
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.models.task import Task
from app.models.focus import FocusSession
from app.models.habit import Habit, HabitLog
from app.models.prayer import PrayerLog

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _today_utc() -> date:
    return datetime.now(timezone.utc).date()


def _week_start() -> date:
    today = _today_utc()
    return today - timedelta(days=6)


@router.get("/today")
async def get_today_analytics(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id: uuid.UUID = current_user.id
    today = _today_utc()

    # Tasks completed today
    tasks_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "completed",
            Task.is_deleted == False,
            func.date(Task.completed_at) == today,
        )
    )
    tasks_completed = tasks_result.scalar() or 0

    # Tasks pending
    pending_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.is_deleted == False,
        )
    )
    tasks_pending = pending_result.scalar() or 0

    # Focus minutes today
    focus_result = await db.execute(
        select(func.coalesce(func.sum(FocusSession.actual_minutes), 0)).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
            func.date(FocusSession.started_at) == today,
        )
    )
    focus_minutes = focus_result.scalar() or 0

    # Focus sessions today
    focus_sessions_result = await db.execute(
        select(func.count(FocusSession.id)).where(
            FocusSession.user_id == user_id,
            FocusSession.status == "completed",
            func.date(FocusSession.started_at) == today,
        )
    )
    focus_sessions = focus_sessions_result.scalar() or 0

    # Habits completed today
    habits_result = await db.execute(
        select(func.count(HabitLog.id)).where(
            HabitLog.user_id == user_id,
            HabitLog.log_date == today,
            HabitLog.is_completed == True,
        )
    )
    habits_completed = habits_result.scalar() or 0

    # Total active habits
    total_habits_result = await db.execute(
        select(func.count(Habit.id)).where(
            Habit.user_id == user_id,
            Habit.is_active == True,
            Habit.is_deleted == False,
        )
    )
    total_habits = total_habits_result.scalar() or 0

    # Prayers completed today
    prayers_result = await db.execute(
        select(func.count(PrayerLog.id)).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date == today,
            PrayerLog.completed == True,
        )
    )
    prayers_completed = prayers_result.scalar() or 0

    # Productivity score (0–100)
    score = _calculate_productivity_score(
        tasks_completed=tasks_completed,
        focus_minutes=int(focus_minutes),
        habits_completed=habits_completed,
        total_habits=total_habits,
        prayers_completed=prayers_completed,
    )

    return {
        "date": today.isoformat(),
        "tasks_completed": tasks_completed,
        "tasks_pending": tasks_pending,
        "focus_minutes": int(focus_minutes),
        "focus_sessions": focus_sessions,
        "habits_completed": habits_completed,
        "total_habits": total_habits,
        "prayers_completed": prayers_completed,
        "total_prayers": 5,
        "productivity_score": score,
    }


@router.get("/weekly")
async def get_weekly_analytics(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id: uuid.UUID = current_user.id
    today = _today_utc()
    week_start = _week_start()

    # Daily breakdown for last 7 days
    daily_stats = []
    for i in range(7):
        day = week_start + timedelta(days=i)

        tasks_r = await db.execute(
            select(func.count(Task.id)).where(
                Task.user_id == user_id,
                Task.status == "completed",
                Task.is_deleted == False,
                func.date(Task.completed_at) == day,
            )
        )

        focus_r = await db.execute(
            select(func.coalesce(func.sum(FocusSession.actual_minutes), 0)).where(
                FocusSession.user_id == user_id,
                FocusSession.status == "completed",
                func.date(FocusSession.started_at) == day,
            )
        )

        habits_r = await db.execute(
            select(func.count(HabitLog.id)).where(
                HabitLog.user_id == user_id,
                HabitLog.log_date == day,
                HabitLog.is_completed == True,
            )
        )

        prayers_r = await db.execute(
            select(func.count(PrayerLog.id)).where(
                PrayerLog.user_id == user_id,
                PrayerLog.prayer_date == day,
                PrayerLog.completed == True,
            )
        )

        daily_stats.append({
            "date": day.isoformat(),
            "day_label": day.strftime("%a"),
            "tasks_completed": tasks_r.scalar() or 0,
            "focus_minutes": int(focus_r.scalar() or 0),
            "habits_completed": habits_r.scalar() or 0,
            "prayers_completed": prayers_r.scalar() or 0,
        })

    # Weekly totals
    total_tasks = sum(d["tasks_completed"] for d in daily_stats)
    total_focus = sum(d["focus_minutes"] for d in daily_stats)
    total_habits = sum(d["habits_completed"] for d in daily_stats)
    total_prayers = sum(d["prayers_completed"] for d in daily_stats)

    # Best streak for habits
    habits_streak_result = await db.execute(
        select(func.max(Habit.current_streak)).where(
            Habit.user_id == user_id,
            Habit.is_deleted == False,
        )
    )
    best_streak = habits_streak_result.scalar() or 0

    # Weekly avg productivity score
    avg_score = int(
        sum(
            _calculate_productivity_score(
                tasks_completed=d["tasks_completed"],
                focus_minutes=d["focus_minutes"],
                habits_completed=d["habits_completed"],
                total_habits=max(1, d["habits_completed"]),
                prayers_completed=d["prayers_completed"],
            )
            for d in daily_stats
        )
        / 7
    )

    return {
        "week_start": week_start.isoformat(),
        "week_end": today.isoformat(),
        "total_tasks_completed": total_tasks,
        "total_focus_minutes": total_focus,
        "total_habits_logged": total_habits,
        "total_prayers_completed": total_prayers,
        "best_habit_streak": best_streak,
        "avg_productivity_score": avg_score,
        "daily_breakdown": daily_stats,
    }


@router.get("/insights")
async def get_insights(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id: uuid.UUID = current_user.id
    today = _today_utc()
    week_start = _week_start()

    insights = []

    # Best focus day
    focus_by_day = []
    for i in range(7):
        day = week_start + timedelta(days=i)
        r = await db.execute(
            select(func.coalesce(func.sum(FocusSession.actual_minutes), 0)).where(
                FocusSession.user_id == user_id,
                FocusSession.status == "completed",
                func.date(FocusSession.started_at) == day,
            )
        )
        focus_by_day.append((day, int(r.scalar() or 0)))

    best_focus_day = max(focus_by_day, key=lambda x: x[1])
    if best_focus_day[1] > 0:
        insights.append({
            "type": "focus",
            "emoji": "⏱️",
            "title": "Best Focus Day",
            "message": f"Your most focused day was {best_focus_day[0].strftime('%A')} with {best_focus_day[1]} minutes of deep work.",
        })

    # Prayer consistency
    prayers_r = await db.execute(
        select(func.count(PrayerLog.id)).where(
            PrayerLog.user_id == user_id,
            PrayerLog.prayer_date >= week_start,
            PrayerLog.completed == True,
        )
    )
    prayers_week = prayers_r.scalar() or 0
    prayer_rate = int((prayers_week / 35) * 100)
    if prayer_rate > 0:
        insights.append({
            "type": "prayer",
            "emoji": "🕌",
            "title": "Prayer Consistency",
            "message": f"You completed {prayer_rate}% of your prayers this week. {'Excellent! 🎉' if prayer_rate >= 80 else 'Keep going! 💪'}",
        })

    # Habit streaks
    top_habit_r = await db.execute(
        select(Habit).where(
            Habit.user_id == user_id,
            Habit.is_deleted == False,
            Habit.current_streak > 0,
        ).order_by(Habit.current_streak.desc()).limit(1)
    )
    top_habit = top_habit_r.scalar_one_or_none()
    if top_habit:
        insights.append({
            "type": "habit",
            "emoji": "🔥",
            "title": "Top Habit Streak",
            "message": f"'{top_habit.title}' is on a {top_habit.current_streak}-day streak! Don't break it!",
        })

    # Tasks this week
    tasks_r = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "completed",
            Task.is_deleted == False,
            func.date(Task.completed_at) >= week_start,
        )
    )
    tasks_week = tasks_r.scalar() or 0
    if tasks_week > 0:
        insights.append({
            "type": "tasks",
            "emoji": "✅",
            "title": "Weekly Task Progress",
            "message": f"You completed {tasks_week} task{'s' if tasks_week != 1 else ''} this week. {'Amazing work! 🚀' if tasks_week >= 10 else 'Keep building momentum! 💪'}",
        })

    # Fallback if no data yet
    if not insights:
        insights.append({
            "type": "welcome",
            "emoji": "🌟",
            "title": "Getting Started",
            "message": "Complete some tasks, habits, and prayers to unlock your personal insights!",
        })

    return {"insights": insights, "generated_at": today.isoformat()}


def _calculate_productivity_score(
    tasks_completed: int,
    focus_minutes: int,
    habits_completed: int,
    total_habits: int,
    prayers_completed: int,
) -> int:
    task_score = min(tasks_completed * 10, 30)
    focus_score = min(int(focus_minutes / 2), 25)
    habit_score = int((habits_completed / max(total_habits, 1)) * 25)
    prayer_score = int((prayers_completed / 5) * 20)
    return min(task_score + focus_score + habit_score + prayer_score, 100)