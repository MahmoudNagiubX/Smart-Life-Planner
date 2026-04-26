import pytest
from pydantic import ValidationError

from app.schemas.settings import OnboardingRequest


def test_onboarding_request_normalizes_contract_payload():
    payload = OnboardingRequest(
        timezone=" Africa/Cairo ",
        language="en",
        prayer_calculation_method="Egypt",
        country=" Egypt ",
        city=" Cairo ",
        goals=["Study", "spiritual growth", "study"],
        wake_time="6:5",
        sleep_time="22:30",
        work_study_windows=[
            {
                "window_type": "study",
                "label": " Evening study ",
                "start_time": "19:0",
                "end_time": "21:00",
                "days": [0, 1, 1, 2],
            }
        ],
        notifications_enabled=False,
        microphone_enabled=True,
        location_enabled=True,
    )

    assert payload.timezone == "Africa/Cairo"
    assert payload.country == "Egypt"
    assert payload.city == "Cairo"
    assert payload.goals == ["study", "spiritual_growth"]
    assert payload.wake_time == "06:05"
    assert payload.work_study_windows[0].label == "Evening study"
    assert payload.work_study_windows[0].start_time == "19:00"
    assert payload.work_study_windows[0].days == [0, 1, 2]


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("language", "fr"),
        ("prayer_calculation_method", "unknown"),
        ("goals", ["unsupported"]),
        ("wake_time", "25:00"),
    ],
)
def test_onboarding_request_rejects_unsupported_values(field, value):
    payload = {
        "timezone": "Africa/Cairo",
        "language": "en",
        "prayer_calculation_method": "MWL",
        "goals": ["study"],
    }
    payload[field] = value

    with pytest.raises(ValidationError):
        OnboardingRequest(**payload)
