from datetime import datetime, time
from zoneinfo import ZoneInfo

import pytest
from pydantic import ValidationError

from app.schemas.dhikr import DhikrReminderCreate, DhikrReminderUpdate
from app.schemas.reminder import ReminderCreate
from app.repositories.dhikr_repository import next_dhikr_occurrence


def test_dhikr_schema_accepts_real_reminder_payload():
    payload = DhikrReminderCreate(
        title="Morning dhikr",
        phrase="SubhanAllah",
        schedule_time=time(7, 30),
        recurrence_rule="daily",
        timezone="Africa/Cairo",
    )

    assert payload.title == "Morning dhikr"
    assert payload.phrase == "SubhanAllah"
    assert payload.recurrence_rule == "daily"


def test_dhikr_schema_rejects_empty_title_and_unknown_recurrence():
    with pytest.raises(ValidationError):
        DhikrReminderCreate(title=" ", schedule_time=time(7, 30))
    with pytest.raises(ValidationError):
        DhikrReminderUpdate(recurrence_rule="hourly")


def test_unified_reminder_contract_supports_dhikr_target():
    import uuid

    payload = ReminderCreate(
        target_type="dhikr",
        target_id=uuid.uuid4(),
        reminder_type="dhikr",
        scheduled_at=datetime(2026, 5, 1, 7, 30, tzinfo=ZoneInfo("UTC")),
    )

    assert payload.target_type == "dhikr"
    assert payload.reminder_type == "dhikr"


def test_next_dhikr_occurrence_is_timezone_aware_and_future():
    now = datetime(2026, 5, 1, 8, 0, tzinfo=ZoneInfo("Africa/Cairo"))
    scheduled = next_dhikr_occurrence(
        time(7, 30),
        timezone_name="Africa/Cairo",
        recurrence_rule="daily",
        now=now,
    )

    assert scheduled.tzinfo is not None
    assert scheduled > now.astimezone(ZoneInfo("UTC"))
