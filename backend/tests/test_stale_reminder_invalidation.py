from app.services.reminder_invalidation import disabled_preference_target_types


def test_disabled_reminder_preferences_map_to_target_types():
    disabled = disabled_preference_target_types(
        {
            "types": {
                "task": False,
                "note": False,
                "prayer": True,
                "quran_goal": False,
            }
        }
    )

    assert disabled == {"task", "note", "quran_goal"}


def test_notifications_disabled_invalidates_all_known_target_types():
    disabled = disabled_preference_target_types(None, notifications_enabled=False)

    assert {
        "task",
        "habit",
        "note",
        "quran_goal",
        "prayer",
        "focus",
        "bedtime",
        "ai_suggestion",
        "location",
    }.issubset(disabled)
