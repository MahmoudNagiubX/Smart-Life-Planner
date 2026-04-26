from datetime import datetime, timezone

from app.services.onboarding_defaults import normalize_goal_keys


def _focus_window_from_wake_time(wake_time: str | None) -> str | None:
    if not wake_time:
        return None
    hour_text = wake_time.split(":", maxsplit=1)[0]
    if not hour_text.isdigit():
        return None
    hour = int(hour_text)
    if hour < 8:
        return "early_morning"
    if hour < 12:
        return "morning"
    if hour < 17:
        return "afternoon"
    return "evening"


def build_ai_recommendation_seed(
    *,
    goals: list[str],
    wake_time: str | None,
    sleep_time: str | None,
    timezone_name: str,
) -> dict:
    goal_tags = normalize_goal_keys(goals)
    rhythm = {
        "timezone": timezone_name,
    }
    if wake_time:
        rhythm["wake_time"] = wake_time
    if sleep_time:
        rhythm["sleep_time"] = sleep_time
    focus_window = _focus_window_from_wake_time(wake_time)
    if focus_window:
        rhythm["preferred_focus_window"] = focus_window

    return {
        "ai_goal_tags": goal_tags,
        "ai_daily_rhythm": rhythm,
        "ai_recommendation_seeded_at": datetime.now(timezone.utc),
    }
