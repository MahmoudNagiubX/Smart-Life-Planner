import uuid
from datetime import datetime, timedelta, timezone
from typing import Any


TASK_REMINDER_PRESET_OFFSETS: dict[str, timedelta] = {
    "at_due_time": timedelta(),
    "10_minutes_before": timedelta(minutes=10),
    "1_hour_before": timedelta(hours=1),
    "1_day_before": timedelta(days=1),
}
TASK_REMINDER_PRESETS = {
    *TASK_REMINDER_PRESET_OFFSETS.keys(),
    "custom",
    "recurring_custom",
}


def task_preset_recurrence_rule(
    preset: str,
    custom_recurrence_rule: str | None = None,
) -> str:
    if preset == "recurring_custom":
        rule = (custom_recurrence_rule or "").strip()
        if not rule:
            raise ValueError("custom_recurrence_rule is required")
        return f"preset:recurring_custom;rule={rule}"
    return f"preset:{preset}"


def task_preset_from_recurrence_rule(recurrence_rule: str | None) -> str | None:
    if not recurrence_rule or not recurrence_rule.startswith("preset:"):
        return None
    return recurrence_rule.removeprefix("preset:").split(";", 1)[0]


def calculate_task_preset_time(
    preset: str,
    *,
    due_at: datetime | None,
    custom_scheduled_at: datetime | None = None,
) -> datetime:
    if preset in TASK_REMINDER_PRESET_OFFSETS:
        if due_at is None:
            raise ValueError("Task due date is required for this preset")
        return due_at - TASK_REMINDER_PRESET_OFFSETS[preset]
    if preset in {"custom", "recurring_custom"}:
        if custom_scheduled_at is None:
            raise ValueError("custom_scheduled_at is required for this preset")
        return custom_scheduled_at
    raise ValueError("Unsupported task reminder preset")


def build_task_reminder_preset_data(
    *,
    task_id: uuid.UUID,
    due_at: datetime | None,
    timezone_name: str,
    presets: list[Any],
) -> list[dict]:
    reminders: list[dict] = []
    seen: set[tuple[str, datetime, str | None]] = set()
    for item in presets:
        preset = item.preset
        scheduled_at = calculate_task_preset_time(
            preset,
            due_at=due_at,
            custom_scheduled_at=item.custom_scheduled_at,
        )
        if scheduled_at.tzinfo is None:
            raise ValueError("Reminder preset datetimes must include timezone info")

        recurrence_rule = task_preset_recurrence_rule(
            preset,
            item.custom_recurrence_rule,
        )
        key = (preset, scheduled_at, recurrence_rule)
        if key in seen:
            continue
        seen.add(key)

        reminders.append(
            {
                "target_type": "task",
                "target_id": task_id,
                "reminder_type": "task_due",
                "scheduled_at": scheduled_at,
                "recurrence_rule": recurrence_rule,
                "timezone": timezone_name,
                "status": "scheduled",
                "channel": item.channel,
                "priority": item.priority,
            }
        )
    return reminders


def is_future_reminder(value: datetime) -> bool:
    return value > datetime.now(timezone.utc)
