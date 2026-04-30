from datetime import datetime, time


def predict_focus_readiness(
    *,
    focus_streak_days: int,
    task_completion_rate_percent: int,
    overload_load_ratio: float,
    wake_time: str | None,
    sleep_time: str | None,
    now: datetime,
) -> dict:
    score = 45
    reasons: list[str] = []

    if focus_streak_days >= 3:
        score += 18
        reasons.append("recent focus streak is strong")
    elif focus_streak_days >= 1:
        score += 10
        reasons.append("recent focus streak is active")
    else:
        score -= 8
        reasons.append("no recent focus streak yet")

    if task_completion_rate_percent >= 70:
        score += 15
        reasons.append("task completion rate is strong")
    elif task_completion_rate_percent >= 40:
        score += 8
        reasons.append("task completion rate is steady")
    elif task_completion_rate_percent > 0:
        score -= 5
        reasons.append("task completion rate is still building")
    else:
        score -= 10
        reasons.append("no recent completed tasks")

    if overload_load_ratio >= 1.0:
        score -= 20
        reasons.append("workload appears overloaded")
    elif overload_load_ratio >= 0.85:
        score -= 12
        reasons.append("workload is close to overload")
    elif overload_load_ratio <= 0.5:
        score += 8
        reasons.append("workload looks manageable")
    else:
        reasons.append("workload is moderate")

    rhythm_score, rhythm_reason = _rhythm_signal(
        wake_time=wake_time,
        sleep_time=sleep_time,
        current_time=now.time(),
    )
    score += rhythm_score
    reasons.append(rhythm_reason)

    hour = now.hour
    if 8 <= hour < 12:
        score += 8
        reasons.append("morning hours are often good for focus")
    elif 12 <= hour < 18:
        score += 5
        reasons.append("current time is still focus-friendly")
    elif hour >= 22 or hour < 5:
        score -= 12
        reasons.append("late hours may reduce focus readiness")
    else:
        reasons.append("current time is neutral for focus")

    clamped_score = max(0, min(100, score))
    return {
        "predicted_focus_readiness": _readiness_label(clamped_score),
        "readiness_score": clamped_score,
        "reasons": _unique_reasons(reasons),
        "signals": {
            "focus_streak_days": max(focus_streak_days, 0),
            "task_completion_rate_percent": max(
                min(task_completion_rate_percent, 100),
                0,
            ),
            "overload_load_ratio": round(max(overload_load_ratio, 0), 2),
            "wake_time": wake_time,
            "sleep_time": sleep_time,
            "current_hour": hour,
        },
    }


def _readiness_label(score: int) -> str:
    if score >= 70:
        return "high"
    if score >= 45:
        return "medium"
    return "low"


def _rhythm_signal(
    *,
    wake_time: str | None,
    sleep_time: str | None,
    current_time: time,
) -> tuple[int, str]:
    wake = _parse_hh_mm(wake_time)
    sleep = _parse_hh_mm(sleep_time)
    if wake is None or sleep is None:
        return 0, "wake and sleep rhythm is not fully set"

    current_minutes = current_time.hour * 60 + current_time.minute
    wake_minutes = wake.hour * 60 + wake.minute
    sleep_minutes = sleep.hour * 60 + sleep.minute

    minutes_after_wake = current_minutes - wake_minutes
    if 60 <= minutes_after_wake <= 8 * 60:
        return 10, "current time fits your wake rhythm"
    if 0 <= minutes_after_wake < 60:
        return -4, "you may still be warming up after waking"

    minutes_until_sleep = sleep_minutes - current_minutes
    if 0 <= minutes_until_sleep <= 90:
        return -12, "current time is close to your sleep window"

    return 0, "current time is outside your strongest saved rhythm window"


def _parse_hh_mm(value: str | None) -> time | None:
    if not value:
        return None
    try:
        hour_text, minute_text = value.split(":", maxsplit=1)
        return time(hour=int(hour_text), minute=int(minute_text))
    except (TypeError, ValueError):
        return None


def _unique_reasons(reasons: list[str]) -> list[str]:
    seen = set()
    unique = []
    for reason in reasons:
        if reason not in seen:
            unique.append(reason)
            seen.add(reason)
    return unique
