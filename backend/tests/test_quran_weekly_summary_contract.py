from datetime import date, timedelta

from pydantic import TypeAdapter

from app.schemas.prayer import QuranWeeklyProgressItem
from app.services.quran_summary import (
    quran_completion_percent,
    quran_current_streak,
)


def test_quran_weekly_item_exposes_pages_read_alias():
    item = QuranWeeklyProgressItem(
        progress_date=date(2026, 4, 30),
        pages_completed=4,
        target_pages=5,
        target_met=False,
        completion_percent=80,
    )

    dumped = item.model_dump()

    assert dumped["pages_completed"] == 4
    assert dumped["pages_read"] == 4
    assert dumped["target_pages"] == 5
    assert dumped["completion_percent"] == 80


def test_quran_completion_percent_is_capped_and_zero_safe():
    assert quran_completion_percent(3, 0) == 0
    assert quran_completion_percent(3, 5) == 60
    assert quran_completion_percent(9, 5) == 100


def test_quran_current_streak_counts_consecutive_target_days_from_today():
    today = date(2026, 4, 30)
    adapter = TypeAdapter(list[QuranWeeklyProgressItem])
    weekly_summary = adapter.validate_python(
        [
            {
                "progress_date": today - timedelta(days=6 - index),
                "pages_completed": pages,
                "target_pages": 2,
                "target_met": pages >= 2,
                "completion_percent": quran_completion_percent(pages, 2),
            }
            for index, pages in enumerate([0, 2, 2, 1, 2, 2, 3])
        ]
    )

    assert quran_current_streak(weekly_summary) == 3
