from datetime import date, datetime, timezone
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.prayer import (
    RamadanDailySummaryResponse,
    RamadanFastingLogResponse,
    RamadanFastingLogUpdate,
)


def test_ramadan_fasting_update_accepts_yes_no_and_optional_note():
    payload = RamadanFastingLogUpdate(
        fasted=True,
        fast_type="voluntary",
        note="Completed with family.",
    )

    assert payload.fasted is True
    assert payload.fast_type == "voluntary"
    assert payload.note == "Completed with family."


def test_ramadan_fasting_update_rejects_long_note():
    with pytest.raises(ValidationError):
        RamadanFastingLogUpdate(fasted=False, note="x" * 501)


def test_ramadan_fasting_update_rejects_unknown_fast_type():
    with pytest.raises(ValidationError):
        RamadanFastingLogUpdate(fasted=True, fast_type="unknown")


def test_ramadan_daily_summary_allows_no_log_yet():
    summary = RamadanDailySummaryResponse(
        date=date(2026, 4, 30),
        today=None,
        month=4,
        year=2026,
        month_fasted_count=0,
        month_not_fasted_count=0,
        month_logged_count=0,
    )

    assert summary.today is None
    assert summary.month_logged_count == 0


def test_ramadan_daily_summary_serializes_today_log_and_month_count():
    now = datetime.now(timezone.utc)
    log = RamadanFastingLogResponse(
        id=uuid4(),
        user_id=uuid4(),
        fasting_date=date(2026, 4, 30),
        fasted=True,
        fast_type="makeup",
        makeup_for_date=date(2026, 4, 5),
        note=None,
        created_at=now,
        updated_at=now,
    )

    summary = RamadanDailySummaryResponse(
        date=date(2026, 4, 30),
        today=log,
        month=4,
        year=2026,
        month_fasted_count=12,
        month_not_fasted_count=1,
        month_logged_count=13,
    )

    assert summary.today is not None
    assert summary.today.fasted is True
    assert summary.today.fast_type == "makeup"
    assert summary.today.makeup_for_date == date(2026, 4, 5)
    assert summary.month_fasted_count == 12
