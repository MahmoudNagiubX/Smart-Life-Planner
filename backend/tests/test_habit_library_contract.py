from datetime import time

import pytest
from pydantic import ValidationError

from app.schemas.habit import HabitCreate


def test_habit_create_accepts_library_categories_and_custom_frequency():
    payload = HabitCreate(
        title="Hydration",
        category="hydration",
        frequency_type="custom",
        frequency_config={"interval_days": 2},
    )

    assert payload.category == "hydration"
    assert payload.frequency_type == "custom"
    assert payload.frequency_config == {"interval_days": 2}


def test_habit_create_rejects_unknown_category():
    with pytest.raises(ValidationError):
        HabitCreate(title="Mystery habit", category="unknown")


def test_habit_create_accepts_reminder_time():
    payload = HabitCreate(title="Read", reminder_time="08:30:00")

    assert payload.reminder_time == time(8, 30)
