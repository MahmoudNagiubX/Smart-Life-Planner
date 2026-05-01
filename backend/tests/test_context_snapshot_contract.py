from datetime import datetime
from uuid import uuid4
from zoneinfo import ZoneInfo

import pytest
from pydantic import ValidationError

from app.schemas.context import ContextSnapshotCreate, ContextSnapshotResponse
from app.services.context_snapshot import (
    classify_local_time_block,
    local_now,
    safe_timezone_name,
)


def test_context_snapshot_validates_energy_level():
    payload = ContextSnapshotCreate(energy_level="HIGH")

    assert payload.energy_level == "high"

    with pytest.raises(ValidationError):
        ContextSnapshotCreate(energy_level="exhausted")


def test_context_time_block_classification():
    assert classify_local_time_block(datetime(2026, 5, 1, 8, 0)) == "morning"
    assert classify_local_time_block(datetime(2026, 5, 1, 14, 0)) == "afternoon"
    assert classify_local_time_block(datetime(2026, 5, 1, 19, 0)) == "evening"
    assert classify_local_time_block(datetime(2026, 5, 1, 23, 0)) == "night"


def test_context_local_now_uses_timezone_safely():
    current = datetime(2026, 5, 1, 12, 0, tzinfo=ZoneInfo("UTC"))

    cairo = local_now("Africa/Cairo", current)
    fallback = local_now("Missing/Zone", current)

    assert cairo.hour == 15
    assert fallback.hour == 12
    assert safe_timezone_name("Missing/Zone") == "UTC"


def test_context_snapshot_response_serializes_optional_contexts():
    now = datetime.now(ZoneInfo("UTC"))
    response = ContextSnapshotResponse(
        id=uuid4(),
        user_id=uuid4(),
        timestamp=now,
        timezone="Africa/Cairo",
        local_time_block="evening",
        energy_level="medium",
        coarse_location_context="Cairo, Egypt",
        weather_summary=None,
        device_context="mobile",
        created_at=now,
    )

    assert response.local_time_block == "evening"
    assert response.coarse_location_context == "Cairo, Egypt"
