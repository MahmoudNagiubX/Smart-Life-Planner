from copy import deepcopy
from typing import Any


DEFAULT_REMINDER_PREFERENCES: dict[str, Any] = {
    "channels": {
        "local": True,
        "push": True,
        "in_app": True,
        "email": False,
    },
    "types": {
        "task": True,
        "habit": True,
        "note": True,
        "quran_goal": True,
        "prayer": True,
        "focus_prompt": True,
        "bedtime": True,
        "ai_suggestion": True,
        "location": False,
    },
    "quiet_hours": {
        "enabled": False,
        "start": "22:00",
        "end": "07:00",
    },
    "timing": {
        "prayer_minutes_before": 10,
        "bedtime_minutes_before": 30,
        "focus_prompt_minutes_before": 10,
    },
}


def default_reminder_preferences() -> dict[str, Any]:
    return deepcopy(DEFAULT_REMINDER_PREFERENCES)
