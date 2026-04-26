"""
H-ASAE: Human-Aware Adaptive Scheduling & Automation Engine
Deterministic, testable, and explainable scheduling core.
"""

from datetime import datetime, date, timedelta, timezone
from typing import Optional
import uuid


# ── Constants ──────────────────────────────────────────────

PRIORITY_WEIGHTS = {"high": 3, "medium": 2, "low": 1}
ENERGY_WEIGHTS = {"high": 3, "medium": 2, "low": 1}
DIFFICULTY_WEIGHTS = {"hard": 3, "medium": 2, "easy": 1}
FLEXIBILITY_WEIGHTS = {"strict": 3, "moderate": 2, "flexible": 1}

# Energy-time match: which energy level fits which hour range
ENERGY_TIME_MAP = {
    "high": list(range(7, 12)) + list(range(16, 19)),   # 7-12 AM, 4-7 PM
    "medium": list(range(12, 16)) + list(range(19, 21)),  # 12-4 PM, 7-9 PM
    "low": list(range(5, 7)) + list(range(21, 24)),      # early morning, late night
}

# Work window: available hours in a standard productive day
WORK_START_HOUR = 7
WORK_END_HOUR = 23
DAILY_AVAILABLE_MINUTES = (WORK_END_HOUR - WORK_START_HOUR) * 60  # 960 min
OVERLOAD_THRESHOLD = 0.85  # 85% capacity = overloaded


# ── Task Readiness ─────────────────────────────────────────

def is_task_eligible(task: dict, completed_task_ids: set[str]) -> bool:
    """
    A task is eligible for scheduling only if:
    1. It is not completed or deleted
    2. All its prerequisites are completed
    3. auto_schedule_enabled is True
    """
    if task.get("status") in ("completed", "deleted"):
        return False

    if not task.get("auto_schedule_enabled", True):
        return False

    for dep_id in task.get("dependency_ids", []):
        if dep_id not in completed_task_ids:
            return False

    return True


# ── Urgency Calculation ────────────────────────────────────

def calculate_urgency(due_at: Optional[datetime], now: datetime) -> float:
    """
    Returns urgency score 0.0 to 1.0.
    Higher = more urgent.
    """
    if not due_at:
        return 0.1  # No deadline = low urgency

    due_at = due_at.replace(tzinfo=timezone.utc) if due_at.tzinfo is None else due_at
    now = now.replace(tzinfo=timezone.utc) if now.tzinfo is None else now

    delta = (due_at - now).total_seconds() / 3600  # hours remaining

    if delta <= 0:
        return 1.0   # Overdue
    elif delta <= 2:
        return 0.95  # Due within 2 hours
    elif delta <= 6:
        return 0.85  # Due within 6 hours
    elif delta <= 24:
        return 0.70  # Due today
    elif delta <= 48:
        return 0.50  # Due tomorrow
    elif delta <= 72:
        return 0.30  # Due in 3 days
    elif delta <= 168:
        return 0.15  # Due this week
    else:
        return 0.05  # Far future


# ── Energy-Time Match ──────────────────────────────────────

def calculate_energy_time_match(energy_required: str, current_hour: int) -> float:
    """
    Returns how well this task's energy requirement matches the current time.
    Score 0.0 to 1.0.
    """
    energy = energy_required.lower()
    best_hours = ENERGY_TIME_MAP.get(energy, ENERGY_TIME_MAP["medium"])
    if current_hour in best_hours:
        return 1.0
    # Check adjacency (within 1 hour of ideal window)
    for h in best_hours:
        if abs(current_hour - h) == 1:
            return 0.6
    return 0.2


# ── Duration Fit ───────────────────────────────────────────

def calculate_duration_fit(
    estimated_minutes: Optional[int],
    available_minutes: int,
) -> float:
    """
    Returns how well the task fits into the available time window.
    Score 0.0 to 1.0.
    """
    if not estimated_minutes or estimated_minutes <= 0:
        estimated_minutes = 30  # Default assumption

    if available_minutes <= 0:
        return 0.0

    ratio = estimated_minutes / available_minutes
    if ratio <= 0.5:
        return 1.0   # Task fits comfortably
    elif ratio <= 0.8:
        return 0.7   # Task fits with some pressure
    elif ratio <= 1.0:
        return 0.4   # Task barely fits
    else:
        return 0.0   # Task does not fit


# ── Weighted Task Score ────────────────────────────────────

def score_task(
    task: dict,
    now: datetime,
    available_minutes: int,
) -> dict:
    """
    Computes a weighted execution score for a task.
    Returns the score and a plain-language explanation.

    Score components:
    - Priority (30%)
    - Urgency (25%)
    - Energy-time match (20%)
    - Duration fit (15%)
    - Flexibility (10%)
    """
    priority = task.get("priority", "medium").lower()
    energy = task.get("energy_required", "medium").lower()
    flexibility = task.get("schedule_flexibility", "flexible").lower()
    due_at = task.get("due_at")
    estimated = task.get("estimated_minutes")

    priority_score = PRIORITY_WEIGHTS.get(priority, 2) / 3
    urgency_score = calculate_urgency(due_at, now)
    energy_score = calculate_energy_time_match(energy, now.hour)
    duration_score = calculate_duration_fit(estimated, available_minutes)
    flexibility_score = FLEXIBILITY_WEIGHTS.get(flexibility, 2) / 3

    # Weighted sum
    total = (
        priority_score * 0.30
        + urgency_score * 0.25
        + energy_score * 0.20
        + duration_score * 0.15
        + flexibility_score * 0.10
    )

    # Build explanation
    reasons = []
    if priority == "high":
        reasons.append("high priority")
    if urgency_score >= 0.70:
        reasons.append("deadline approaching")
    if energy_score >= 0.8:
        reasons.append("good energy match for this time")
    if duration_score >= 0.7:
        reasons.append("fits well in available time")
    if flexibility == "strict":
        reasons.append("strict timing required")

    explanation = (
        f"Score {total:.2f}: " + ", ".join(reasons)
        if reasons
        else f"Score {total:.2f}: standard scheduling"
    )

    return {
        "task_id": str(task.get("id", "")),
        "title": task.get("title", ""),
        "score": round(total, 4),
        "components": {
            "priority": round(priority_score, 4),
            "urgency": round(urgency_score, 4),
            "energy_time_match": round(energy_score, 4),
            "duration_fit": round(duration_score, 4),
            "flexibility": round(flexibility_score, 4),
        },
        "explanation": explanation,
    }


# ── Rank Tasks ─────────────────────────────────────────────

def rank_tasks(
    tasks: list[dict],
    now: datetime,
    available_minutes: int,
    completed_task_ids: set[str],
) -> list[dict]:
    """
    Filters eligible tasks, scores them, and returns ranked list
    highest score first.
    """
    eligible = [t for t in tasks if is_task_eligible(t, completed_task_ids)]
    scored = [score_task(t, now, available_minutes) for t in eligible]
    return sorted(scored, key=lambda x: x["score"], reverse=True)


# ── Overload Detection ─────────────────────────────────────

def detect_overload(
    tasks: list[dict],
    already_scheduled_minutes: int = 0,
) -> dict:
    """
    Detects if the user's pending tasks exceed daily capacity.
    Returns overload state and message.
    """
    total_pending_minutes = sum(
        t.get("estimated_minutes") or 30
        for t in tasks
        if t.get("status") == "pending"
    )

    total_needed = total_pending_minutes + already_scheduled_minutes
    capacity = DAILY_AVAILABLE_MINUTES
    load_ratio = total_needed / capacity

    if load_ratio > OVERLOAD_THRESHOLD:
        overloaded_by = total_needed - int(capacity * OVERLOAD_THRESHOLD)
        return {
            "overload_detected": True,
            "load_ratio": round(load_ratio, 2),
            "total_needed_minutes": total_needed,
            "available_minutes": capacity,
            "overloaded_by_minutes": overloaded_by,
            "message": (
                f"Your schedule is overloaded by ~{overloaded_by} minutes. "
                f"Consider deferring low-priority tasks or splitting them across days."
            ),
        }

    return {
        "overload_detected": False,
        "load_ratio": round(load_ratio, 2),
        "total_needed_minutes": total_needed,
        "available_minutes": capacity,
        "overloaded_by_minutes": 0,
        "message": None,
    }


# ── Next Best Action ───────────────────────────────────────

def get_next_best_action(
    tasks: list[dict],
    prayer_times: list[dict],
    now: datetime,
    completed_task_ids: set[str],
) -> dict:
    """
    Returns the single best task to do right now using H-ASAE scoring.
    Respects upcoming prayer times as hard constraints.
    """
    # Find next prayer time
    next_prayer = None
    next_prayer_dt = None
    for prayer in prayer_times:
        pt = prayer.get("scheduled_at")
        if pt:
            try:
                pdt = datetime.fromisoformat(pt.replace("Z", "+00:00"))
                pdt = pdt.replace(tzinfo=timezone.utc) if pdt.tzinfo is None else pdt
                now_utc = now.replace(tzinfo=timezone.utc) if now.tzinfo is None else now
                if pdt > now_utc:
                    if next_prayer_dt is None or pdt < next_prayer_dt:
                        next_prayer_dt = pdt
                        next_prayer = prayer.get("prayer_name")
            except Exception:
                pass

    # Calculate available window before next prayer
    if next_prayer_dt:
        now_utc = now.replace(tzinfo=timezone.utc) if now.tzinfo is None else now
        minutes_until_prayer = max(0, int((next_prayer_dt - now_utc).total_seconds() / 60))
    else:
        minutes_until_prayer = 120  # Default 2 hours

    ranked = rank_tasks(tasks, now, minutes_until_prayer, completed_task_ids)

    if not ranked:
        return {
            "task_id": None,
            "title": None,
            "score": 0,
            "reason": "No eligible tasks found.",
            "alternative": None,
            "minutes_until_prayer": minutes_until_prayer,
            "next_prayer": next_prayer,
        }

    best = ranked[0]
    alternative = ranked[1] if len(ranked) > 1 else None

    reason_parts = [best["explanation"]]
    if next_prayer and minutes_until_prayer < 60:
        reason_parts.append(
            f"{next_prayer.capitalize()} prayer in {minutes_until_prayer} min - start soon!"
        )

    return {
        "task_id": best["task_id"],
        "title": best["title"],
        "score": best["score"],
        "reason": " | ".join(reason_parts),
        "components": best["components"],
        "alternative": {
            "task_id": alternative["task_id"],
            "title": alternative["title"],
            "score": alternative["score"],
        } if alternative else None,
        "minutes_until_prayer": minutes_until_prayer,
        "next_prayer": next_prayer,
    }


# ── Future-Only Replanning ─────────────────────────────────

def get_replan_candidates(
    tasks: list[dict],
    now: datetime,
    completed_task_ids: set[str],
    trigger_event: str = "task_completed",
) -> dict:
    """
    After an automation event, identifies which tasks need replanning.
    ONLY touches future schedule — never modifies past blocks.
    """
    eligible = [t for t in tasks if is_task_eligible(t, completed_task_ids)]

    high_urgency = [
        t for t in eligible
        if calculate_urgency(t.get("due_at"), now) >= 0.70
    ]

    return {
        "trigger_event": trigger_event,
        "replanning_scope": "future_only",
        "candidates": len(eligible),
        "high_urgency_count": len(high_urgency),
        "high_urgency_tasks": [
            {"task_id": str(t["id"]), "title": t["title"]}
            for t in high_urgency[:3]
        ],
        "recommendation": (
            "Reschedule high-urgency tasks first"
            if high_urgency
            else "No urgent replanning needed"
        ),
        "timestamp": now.isoformat(),
    }
