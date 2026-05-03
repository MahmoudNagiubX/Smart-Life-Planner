"""
H-ASAE: Human-Aware Adaptive Scheduling & Automation Engine
Deterministic, testable, and explainable scheduling core.
"""

from datetime import datetime, date, time, timedelta, timezone
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
    Algorithm: Rule-Based Filtering
    Used for: H-ASAE scheduling eligibility.
    Complexity: O(d), where d is the number of dependencies.
    Notes: Excludes completed/deleted tasks and tasks with unmet prerequisites.

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
    Algorithm: Rule-Based Classification
    Used for: Deadline urgency scoring.
    Complexity: O(1)
    Notes: Maps remaining time windows to urgency scores.

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
    Algorithm: Weighted Scoring
    Used for: Smart task ranking in H-ASAE.
    Complexity: O(1) per task.
    Notes: Combines priority, urgency, energy fit, duration fit, and flexibility.

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
    Algorithm: Ranking by Weighted Score
    Used for: H-ASAE ranked task recommendations.
    Complexity: O(n log n) after O(n) filtering and scoring.
    Notes: Sorts eligible tasks from highest score to lowest score.

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
    Algorithm: Aggregation and Threshold Classification
    Used for: Daily schedule overload detection.
    Complexity: O(n)
    Notes: Sums pending task durations and compares load against capacity.

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
    Algorithm: Greedy Selection
    Used for: Choosing the best next task before the next prayer window.
    Complexity: O(p + n log n), where p is prayers and n is tasks.
    Notes: Picks the highest ranked currently eligible task.

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
    Algorithm: Rule-Based Classification
    Used for: Future-only replanning candidate detection.
    Complexity: O(n)
    Notes: Finds eligible tasks and classifies high-urgency candidates.

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


# --- Daily Smart Plan -------------------------------------------------------

def _parse_clock(value: Optional[str], fallback: time) -> time:
    if not value:
        return fallback
    try:
        hour, minute = value.split(":", 1)
        return time(hour=int(hour), minute=int(minute))
    except Exception:
        return fallback


def _minutes_between(start: datetime, end: datetime) -> int:
    return max(0, int((end - start).total_seconds() / 60))


def _as_utc(value: datetime) -> datetime:
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value


def _subtract_interval(
    windows: list[tuple[datetime, datetime]],
    blocked_start: datetime,
    blocked_end: datetime,
) -> list[tuple[datetime, datetime]]:
    next_windows: list[tuple[datetime, datetime]] = []
    for start, end in windows:
        if blocked_end <= start or blocked_start >= end:
            next_windows.append((start, end))
            continue
        if blocked_start > start:
            next_windows.append((start, blocked_start))
        if blocked_end < end:
            next_windows.append((blocked_end, end))
    return [
        (start, end)
        for start, end in next_windows
        if _minutes_between(start, end) >= 10
    ]


def _fits_date(value: datetime, target_date: date) -> bool:
    return value.date() == target_date


def generate_daily_smart_plan(
    *,
    tasks: list[dict],
    prayer_times: list[dict],
    target_date: date,
    wake_time: Optional[str],
    sleep_time: Optional[str],
    completed_task_ids: set[str],
    existing_blocks: list[dict] | None = None,
) -> dict:
    """
    Feature: H-ASAE - Human-Aware Adaptive Scheduling & Automation Engine
    Algorithm: Greedy Scheduling + Weighted Scoring + Interval Conflict Detection
    Purpose: Selects the best tasks that fit the user's available time while
    respecting prayer/focus constraints.
    Complexity: O(n log n + p + b), where n is tasks, p is prayer blocks, and
    b is existing protected schedule blocks.

    The function returns a preview only. Persisting the plan is handled by the
    authenticated API after explicit user confirmation.
    """
    day_start_time = _parse_clock(wake_time, time(hour=7))
    day_end_time = _parse_clock(sleep_time, time(hour=23))
    day_start = datetime.combine(target_date, day_start_time, tzinfo=timezone.utc)
    day_end = datetime.combine(target_date, day_end_time, tzinfo=timezone.utc)
    if day_end <= day_start:
        day_end += timedelta(days=1)

    protected_blocks = existing_blocks or []
    windows: list[tuple[datetime, datetime]] = [(day_start, day_end)]
    output_blocks: list[dict] = []

    # Algorithm: Prayer-Aware Blocking
    # Used for: Preventing generated focus/task blocks from overlapping prayers.
    # Complexity: O(p * w), where w is the number of current free windows.
    for prayer in prayer_times:
        scheduled_at = prayer.get("scheduled_at")
        if not isinstance(scheduled_at, datetime) or not _fits_date(scheduled_at, target_date):
            continue
        scheduled_at = _as_utc(scheduled_at)
        prayer_end = scheduled_at + timedelta(minutes=15)
        windows = _subtract_interval(windows, scheduled_at, prayer_end)
        output_blocks.append({
            "task_id": None,
            "block_type": "prayer",
            "title": f"{str(prayer.get('prayer_name', 'Prayer')).title()} Prayer",
            "start_time": scheduled_at,
            "end_time": prayer_end,
            "is_locked": True,
            "score": None,
            "explanation": "[H-ASAE] Prayer-aware protected spiritual window.",
        })

    for block in protected_blocks:
        start_time = block.get("start_time")
        end_time = block.get("end_time")
        if isinstance(start_time, datetime) and isinstance(end_time, datetime):
            windows = _subtract_interval(windows, _as_utc(start_time), _as_utc(end_time))

    available_minutes = sum(_minutes_between(start, end) for start, end in windows)
    now = datetime.now(timezone.utc)
    ranked = rank_tasks(tasks, now, available_minutes, completed_task_ids)
    tasks_by_id = {str(task.get("id")): task for task in tasks}

    selected_tasks: list[dict] = []
    skipped_tasks: list[dict] = []
    buffer_minutes = 5

    # Algorithm: Greedy Scheduling
    # Used for: Selecting the highest-scored eligible task that fits a remaining
    # free interval, then moving to the next best candidate.
    # Complexity: O(n * w) after O(n log n) weighted ranking.
    for ranked_task in ranked:
        task = tasks_by_id.get(ranked_task["task_id"])
        if not task:
            continue
        duration = task.get("estimated_minutes") or 30
        placed = False

        for index, (window_start, window_end) in enumerate(list(windows)):
            if _minutes_between(window_start, window_end) < duration:
                continue
            start = window_start
            end = start + timedelta(minutes=duration)
            priority = str(task.get("priority", "medium")).lower()
            block_type = "focus" if priority == "high" or duration >= 45 else "task"
            title_prefix = "Focus: " if block_type == "focus" else ""
            output_blocks.append({
                "task_id": task.get("id"),
                "block_type": block_type,
                "title": f"{title_prefix}{task.get('title', 'Untitled task')}",
                "start_time": start,
                "end_time": end,
                "is_locked": False,
                "score": ranked_task["score"],
                "explanation": f"[H-ASAE] {ranked_task['explanation']}",
            })
            selected_tasks.append({
                "task_id": ranked_task["task_id"],
                "title": ranked_task["title"],
                "score": ranked_task["score"],
                "reason": ranked_task["explanation"],
                "duration_minutes": duration,
            })

            next_start = end + timedelta(minutes=buffer_minutes)
            windows.pop(index)
            if next_start < window_end:
                windows.insert(index, (next_start, window_end))
            placed = True
            break

        if not placed:
            skipped_tasks.append({
                "task_id": ranked_task["task_id"],
                "title": ranked_task["title"],
                "reason": "Does not fit the remaining prayer-aware time windows.",
            })

    total_task_minutes = sum(
        task.get("estimated_minutes") or 30
        for task in tasks
        if task.get("status") == "pending"
        and is_task_eligible(task, completed_task_ids)
    )
    scheduled_task_minutes = sum(item["duration_minutes"] for item in selected_tasks)
    overload_warning = total_task_minutes > available_minutes or bool(skipped_tasks)
    overload_message = None
    if overload_warning:
        overflow = max(0, total_task_minutes - available_minutes)
        overload_message = (
            "Your day is overloaded. H-ASAE scheduled the highest-value work "
            "first and recommends moving lower-priority tasks."
        )
        if overflow > 0:
            overload_message += f" Estimated overflow: {overflow} minutes."

    output_blocks.sort(key=lambda item: item["start_time"])
    explanation = (
        "This plan prioritizes urgent high-priority tasks, creates focus blocks "
        "for demanding work, and keeps prayer windows protected."
    )

    return {
        "date": target_date.isoformat(),
        "blocks": output_blocks,
        "selected_tasks": selected_tasks,
        "skipped_tasks": skipped_tasks,
        "overload_warning": overload_warning,
        "overload_message": overload_message,
        "total_task_minutes": total_task_minutes,
        "scheduled_task_minutes": scheduled_task_minutes,
        "available_minutes": available_minutes,
        "explanation": explanation,
        "requires_confirmation": True,
        "persisted": False,
    }
