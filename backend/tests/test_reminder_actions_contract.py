from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.schemas.reminder import ReminderRescheduleRequest, ReminderSnoozeRequest


def test_reminder_snooze_accepts_supported_actions_only():
    assert ReminderSnoozeRequest(minutes=10).minutes == 10
    assert ReminderSnoozeRequest(minutes=60).minutes == 60

    with pytest.raises(ValidationError):
        ReminderSnoozeRequest(minutes=15)


def test_reminder_reschedule_requires_timezone_aware_datetime():
    payload = ReminderRescheduleRequest(
        scheduled_at=datetime(2026, 4, 28, 12, 0, tzinfo=timezone.utc)
    )

    assert payload.scheduled_at.tzinfo is not None

    with pytest.raises(ValidationError):
        ReminderRescheduleRequest(scheduled_at=datetime(2026, 4, 28, 12, 0))
