from datetime import datetime
from zoneinfo import ZoneInfo

from app.services.productivity_prediction import predict_focus_readiness


def test_prediction_is_conservative_without_recent_history():
    result = predict_focus_readiness(
        focus_streak_days=0,
        task_completion_rate_percent=0,
        overload_load_ratio=0.4,
        wake_time=None,
        sleep_time=None,
        now=datetime(2026, 5, 10, 10, 0, tzinfo=ZoneInfo("UTC")),
    )

    assert result["predicted_focus_readiness"] == "low"
    assert result["readiness_score"] < 70
    assert "no recent focus streak yet" in result["reasons"]
    assert "no recent completed tasks" in result["reasons"]


def test_prediction_improves_with_focus_streak_and_completion():
    result = predict_focus_readiness(
        focus_streak_days=4,
        task_completion_rate_percent=80,
        overload_load_ratio=0.45,
        wake_time="06:30",
        sleep_time="22:30",
        now=datetime(2026, 5, 10, 9, 0, tzinfo=ZoneInfo("UTC")),
    )

    assert result["predicted_focus_readiness"] == "high"
    assert result["readiness_score"] >= 70
    assert "recent focus streak is strong" in result["reasons"]
    assert "task completion rate is strong" in result["reasons"]


def test_prediction_penalizes_overload_and_late_hours():
    result = predict_focus_readiness(
        focus_streak_days=1,
        task_completion_rate_percent=35,
        overload_load_ratio=1.2,
        wake_time="06:00",
        sleep_time="22:00",
        now=datetime(2026, 5, 10, 23, 0, tzinfo=ZoneInfo("UTC")),
    )

    assert result["predicted_focus_readiness"] == "low"
    assert "workload appears overloaded" in result["reasons"]
    assert "late hours may reduce focus readiness" in result["reasons"]
