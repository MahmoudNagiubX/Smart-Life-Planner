import uuid
from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.schemas.reminder import TaskReminderPresetItem, TaskReminderPresetRequest
from app.services.task_reminder_presets import (
    build_task_reminder_preset_data,
    calculate_task_preset_time,
    task_preset_from_recurrence_rule,
)


def test_task_due_preset_times_are_relative_to_due_date():
    due_at = datetime(2026, 4, 29, 12, 0, tzinfo=timezone.utc)

    assert calculate_task_preset_time("at_due_time", due_at=due_at) == due_at
    assert calculate_task_preset_time(
        "10_minutes_before",
        due_at=due_at,
    ) == datetime(2026, 4, 29, 11, 50, tzinfo=timezone.utc)
    assert calculate_task_preset_time(
        "1_hour_before",
        due_at=due_at,
    ) == datetime(2026, 4, 29, 11, 0, tzinfo=timezone.utc)


def test_task_reminder_preset_request_accepts_multiple_presets():
    task_id = uuid.uuid4()
    payload = TaskReminderPresetRequest(
        task_id=task_id,
        presets=[
            {"preset": "at_due_time"},
            {"preset": "10_minutes_before"},
        ],
        timezone="Africa/Cairo",
    )

    assert payload.task_id == task_id
    assert [item.preset for item in payload.presets] == [
        "at_due_time",
        "10_minutes_before",
    ]


def test_custom_and_recurring_presets_require_safe_fields():
    with pytest.raises(ValidationError):
        TaskReminderPresetItem(preset="custom")

    with pytest.raises(ValidationError):
        TaskReminderPresetItem(
            preset="recurring_custom",
            custom_scheduled_at=datetime(2026, 4, 29, 12, 0, tzinfo=timezone.utc),
        )


def test_build_task_reminder_preset_data_marks_preset_rules():
    task_id = uuid.uuid4()
    due_at = datetime(2026, 4, 29, 12, 0, tzinfo=timezone.utc)
    presets = [
        TaskReminderPresetItem(preset="1_day_before"),
        TaskReminderPresetItem(
            preset="recurring_custom",
            custom_scheduled_at=datetime(2026, 4, 29, 9, 0, tzinfo=timezone.utc),
            custom_recurrence_rule="FREQ=WEEKLY;BYDAY=MO",
        ),
    ]

    reminders = build_task_reminder_preset_data(
        task_id=task_id,
        due_at=due_at,
        timezone_name="Africa/Cairo",
        presets=presets,
    )

    assert reminders[0]["scheduled_at"] == datetime(
        2026,
        4,
        28,
        12,
        0,
        tzinfo=timezone.utc,
    )
    assert reminders[0]["recurrence_rule"] == "preset:1_day_before"
    assert task_preset_from_recurrence_rule(
        reminders[1]["recurrence_rule"]
    ) == "recurring_custom"
