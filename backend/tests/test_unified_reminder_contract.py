import uuid
from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.schemas.reminder import ReminderCreate, ReminderUpdate


def test_unified_reminder_create_accepts_core_fields():
    target_id = uuid.uuid4()
    payload = ReminderCreate(
        target_type="task",
        target_id=target_id,
        reminder_type="task_due",
        scheduled_at=datetime(2026, 4, 28, 12, 0, tzinfo=timezone.utc),
        timezone="Africa/Cairo",
        channel="local",
        priority="high",
    )

    assert payload.target_type == "task"
    assert payload.target_id == target_id
    assert payload.status == "scheduled"
    assert payload.channel == "local"
    assert payload.priority == "high"


def test_unified_reminder_requires_target_id_for_owned_targets():
    with pytest.raises(ValidationError):
        ReminderCreate(
            target_type="note",
            reminder_type="note",
            scheduled_at=datetime(2026, 4, 28, 12, 0, tzinfo=timezone.utc),
        )


def test_unified_reminder_rejects_naive_datetimes():
    with pytest.raises(ValidationError):
        ReminderCreate(
            target_type="bedtime",
            reminder_type="bedtime",
            scheduled_at=datetime(2026, 4, 28, 12, 0),
        )


def test_unified_reminder_update_validates_status_channel_and_priority():
    update = ReminderUpdate(status="snoozed", channel="in_app", priority="urgent")

    assert update.status == "snoozed"
    assert update.channel == "in_app"
    assert update.priority == "urgent"

    with pytest.raises(ValidationError):
        ReminderUpdate(status="unknown")
