import pytest
from pydantic import ValidationError

from app.schemas.settings import (
    DEFAULT_DASHBOARD_WIDGETS,
    SettingsUpdate,
    validate_dashboard_widgets,
)


def test_dashboard_widgets_accept_unique_supported_order():
    widgets = ["ai_plan", "top_tasks", "ai_plan", "quran_goal"]

    normalized = validate_dashboard_widgets(widgets)

    assert normalized == ["ai_plan", "top_tasks", "quran_goal"]


def test_dashboard_widgets_reject_unknown_widget():
    with pytest.raises(ValueError):
        validate_dashboard_widgets(["top_tasks", "unknown"])


def test_settings_update_validates_dashboard_widgets():
    payload = SettingsUpdate(dashboard_widgets=["focus_shortcut", "top_tasks"])

    assert payload.dashboard_widgets == ["focus_shortcut", "top_tasks"]


def test_default_dashboard_widgets_include_required_mvp_widgets():
    assert DEFAULT_DASHBOARD_WIDGETS == [
        "top_tasks",
        "next_prayer",
        "habit_snapshot",
        "journal_prompt",
        "ai_plan",
        "focus_shortcut",
        "productivity_score",
        "quran_goal",
    ]


def test_dashboard_widgets_allow_empty_list_for_hidden_all():
    assert validate_dashboard_widgets([]) == []



def test_settings_update_rejects_unknown_dashboard_widget():
    with pytest.raises(ValidationError):
        SettingsUpdate(dashboard_widgets=["top_tasks", "bad_widget"])


def test_settings_update_accepts_prayer_coordinates():
    payload = SettingsUpdate(prayer_location_lat=30.044, prayer_location_lng=31.236)

    assert payload.prayer_location_lat == 30.044
    assert payload.prayer_location_lng == 31.236


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("prayer_location_lat", 91),
        ("prayer_location_lat", -91),
        ("prayer_location_lng", 181),
        ("prayer_location_lng", -181),
    ],
)
def test_settings_update_rejects_invalid_prayer_coordinates(field, value):
    with pytest.raises(ValidationError):
        SettingsUpdate(**{field: value})
