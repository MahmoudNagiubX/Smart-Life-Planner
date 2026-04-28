import pytest
from pydantic import ValidationError

from app.core.reminder_preferences import default_reminder_preferences
from app.schemas.settings import ReminderPreferences, SettingsUpdate


def test_default_reminder_preferences_include_channels_types_and_timing():
    preferences = ReminderPreferences(**default_reminder_preferences())

    assert preferences.channels.local is True
    assert preferences.channels.in_app is True
    assert preferences.channels.email is False
    assert preferences.types.habit is True
    assert preferences.types.prayer is True
    assert preferences.quiet_hours.start == "22:00"
    assert preferences.timing.prayer_minutes_before == 10


def test_settings_update_accepts_reminder_type_toggle():
    payload = SettingsUpdate(
        reminder_preferences={
            "types": {"habit": False},
            "channels": {"local": True, "in_app": True},
        }
    )

    assert payload.reminder_preferences is not None
    assert payload.reminder_preferences.types.habit is False
    assert payload.reminder_preferences.types.prayer is True


def test_reminder_preferences_reject_invalid_quiet_hours():
    with pytest.raises(ValidationError):
        SettingsUpdate(
            reminder_preferences={
                "quiet_hours": {
                    "enabled": True,
                    "start": "25:00",
                    "end": "07:00",
                }
            }
        )


def test_reminder_preferences_reject_out_of_range_timing():
    with pytest.raises(ValidationError):
        SettingsUpdate(
            reminder_preferences={
                "timing": {"prayer_minutes_before": 999},
            }
        )
