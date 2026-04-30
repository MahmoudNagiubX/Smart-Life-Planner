import pytest
from pydantic import ValidationError

from app.schemas.focus import FocusSettingsUpdate


def test_focus_settings_update_accepts_valid_preferences():
    payload = FocusSettingsUpdate(
        default_focus_minutes=45,
        short_break_minutes=7,
        long_break_minutes=20,
        sessions_before_long_break=3,
        continuous_mode_enabled=True,
        ambient_sound_key="RAIN",
        distraction_free_mode_enabled=True,
    )

    assert payload.default_focus_minutes == 45
    assert payload.short_break_minutes == 7
    assert payload.long_break_minutes == 20
    assert payload.sessions_before_long_break == 3
    assert payload.continuous_mode_enabled is True
    assert payload.ambient_sound_key == "rain"
    assert payload.distraction_free_mode_enabled is True


@pytest.mark.parametrize(
    "field,value",
    [
        ("default_focus_minutes", 4),
        ("short_break_minutes", 0),
        ("long_break_minutes", 4),
        ("sessions_before_long_break", 0),
    ],
)
def test_focus_settings_rejects_out_of_range_values(field, value):
    with pytest.raises(ValidationError):
        FocusSettingsUpdate(**{field: value})


def test_focus_settings_rejects_unsupported_ambient_sound():
    with pytest.raises(ValidationError):
        FocusSettingsUpdate(ambient_sound_key="thunderstorm")
