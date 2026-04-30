from datetime import datetime, timezone
from typing import Any


PRIORITY_SCORE = {
    "high": 60,
    "medium": 35,
    "low": 15,
}


def build_focus_recommendation(
    tasks: list[Any],
    *,
    default_duration_minutes: int = 25,
    now: datetime | None = None,
) -> dict:
    current_time = now or datetime.now(timezone.utc)
    candidates = [_score_task(task, current_time) for task in tasks]
    candidates = [candidate for candidate in candidates if candidate["task_id"]]

    if not candidates:
        return {
            "task_id": None,
            "title": None,
            "recommended_duration_minutes": default_duration_minutes,
            "reasons": ["No pending tasks are available for focus."],
            "confidence": "high",
            "fallback_used": True,
            "explanation": "No pending tasks are available for focus.",
        }

    selected = max(candidates, key=lambda candidate: candidate["score"])
    duration = _recommended_duration(
        selected["estimated_minutes"],
        default_duration_minutes,
    )

    return {
        "task_id": selected["task_id"],
        "title": selected["title"],
        "recommended_duration_minutes": duration,
        "reasons": selected["reasons"],
        "confidence": _confidence(selected["score"]),
        "fallback_used": True,
        "explanation": _deterministic_explanation(selected["reasons"], duration),
    }


def apply_ai_focus_explanation(
    recommendation: dict,
    explanation: str | None,
) -> dict:
    if not explanation or not explanation.strip():
        return recommendation
    updated = dict(recommendation)
    updated["explanation"] = explanation.strip()[:240]
    updated["fallback_used"] = False
    return updated


def _score_task(task: Any, now: datetime) -> dict:
    title = getattr(task, "title", None)
    task_id = getattr(task, "id", None)
    priority = (getattr(task, "priority", None) or "medium").lower()
    estimated_minutes = getattr(task, "estimated_minutes", None)
    energy_required = (getattr(task, "energy_required", None) or "medium").lower()
    due_at = getattr(task, "due_at", None)

    score = PRIORITY_SCORE.get(priority, PRIORITY_SCORE["medium"])
    reasons = [_priority_reason(priority)]

    if due_at is not None:
        due_at = _normalize_datetime(due_at)
        hours_until_due = (due_at - now).total_seconds() / 3600
        if hours_until_due < 0:
            score += 55
            reasons.append("overdue")
        elif hours_until_due <= 24:
            score += 45
            reasons.append("due within 24 hours")
        elif hours_until_due <= 72:
            score += 30
            reasons.append("due soon")
        elif hours_until_due <= 168:
            score += 15
            reasons.append("due this week")

    if estimated_minutes is None:
        score += 5
        reasons.append("duration can fit a standard focus block")
    elif estimated_minutes <= 30:
        score += 18
        reasons.append("short enough to finish in one focus block")
    elif estimated_minutes <= 60:
        score += 12
        reasons.append("fits a focused work block")
    elif getattr(task, "is_splittable", False):
        score += 8
        reasons.append("can be split into focus blocks")
    else:
        score -= 8
        reasons.append("longer task, start with one focused block")

    if energy_required == "low":
        score += 6
        reasons.append("low energy requirement")
    elif energy_required == "high":
        score += 2
        reasons.append("best handled with protected focus")

    return {
        "task_id": str(task_id) if task_id else None,
        "title": title,
        "estimated_minutes": estimated_minutes,
        "score": score,
        "reasons": _unique_reasons(reasons),
    }


def _priority_reason(priority: str) -> str:
    if priority == "high":
        return "high priority"
    if priority == "low":
        return "low priority but still actionable"
    return "medium priority"


def _normalize_datetime(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _recommended_duration(
    estimated_minutes: int | None,
    default_duration_minutes: int,
) -> int:
    default_duration_minutes = max(5, min(default_duration_minutes, 120))
    if estimated_minutes is None or estimated_minutes <= 0:
        return default_duration_minutes
    return max(5, min(estimated_minutes, default_duration_minutes))


def _confidence(score: int) -> str:
    if score >= 100:
        return "high"
    if score >= 65:
        return "medium"
    return "low"


def _deterministic_explanation(reasons: list[str], duration: int) -> str:
    reason_text = ", ".join(reasons[:3])
    return f"Recommended for {duration} minutes because it is {reason_text}."


def _unique_reasons(reasons: list[str]) -> list[str]:
    seen = set()
    unique = []
    for reason in reasons:
        if reason not in seen:
            unique.append(reason)
            seen.add(reason)
    return unique
