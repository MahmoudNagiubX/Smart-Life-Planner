from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.core.reminder_preferences import default_reminder_preferences
from app.schemas.reminder import ReminderCreate, ReminderUpdate, TaskReminderPresetItem
from app.schemas.settings import ReminderPreferences


def test_persistent_reminder_requires_important_task_priority():
    payload = ReminderCreate(
        target_type="task",
        target_id="00000000-0000-0000-0000-000000000001",
        reminder_type="task_due",
        scheduled_at=datetime(2026, 4, 28, 12, 0, tzinfo=timezone.utc),
        priority="high",
        is_persistent=True,
    )

    assert payload.is_persistent is True
    assert payload.persistent_interval_minutes == 30
    assert payload.persistent_max_occurrences == 3

    with pytest.raises(ValidationError):
        ReminderCreate(
            target_type="task",
            target_id="00000000-0000-0000-0000-000000000001",
            reminder_type="task_due",
            scheduled_at=datetime(2026, 4, 28, 12, 0, tzinfo=timezone.utc),
            priority="normal",
            is_persistent=True,
        )


def test_persistent_frequency_is_limited():
    with pytest.raises(ValidationError):
        TaskReminderPresetItem(
            preset="at_due_time",
            priority="high",
            is_persistent=True,
            persistent_interval_minutes=5,
        )

    with pytest.raises(ValidationError):
        ReminderUpdate(persistent_max_occurrences=20)


def test_constant_reminders_global_preference_defaults_enabled():
    preferences = ReminderPreferences(**default_reminder_preferences())

    assert preferences.types.constant_reminders is True
