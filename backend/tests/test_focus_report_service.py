from datetime import date

from app.services.focus_report import (
    focus_completion_rate,
    focus_current_streak,
    focus_longest_streak,
    focus_report_summary,
)


def test_focus_current_streak_counts_today_and_previous_days():
    today = date(2026, 5, 10)
    focus_days = {
        date(2026, 5, 8),
        date(2026, 5, 9),
        date(2026, 5, 10),
    }

    assert focus_current_streak(focus_days, today) == 3


def test_focus_current_streak_keeps_yesterday_streak_active():
    today = date(2026, 5, 10)
    focus_days = {date(2026, 5, 8), date(2026, 5, 9)}

    assert focus_current_streak(focus_days, today) == 2


def test_focus_longest_streak_uses_consecutive_focus_days():
    focus_days = [
        date(2026, 5, 1),
        date(2026, 5, 3),
        date(2026, 5, 4),
        date(2026, 5, 5),
    ]

    assert focus_longest_streak(focus_days) == 3


def test_focus_completion_rate_uses_closed_sessions():
    assert focus_completion_rate(completed_sessions=3, closed_sessions=4) == 75
    assert focus_completion_rate(completed_sessions=0, closed_sessions=0) == 0


def test_focus_report_summary_includes_core_metrics():
    summary = focus_report_summary(
        today_minutes=50,
        today_sessions=2,
        week_minutes=180,
        current_streak_days=3,
        completion_rate_percent=80,
    )

    assert "Today: 50 minutes" in summary
    assert "Weekly total is 180 minutes" in summary
    assert "80% completion rate" in summary
