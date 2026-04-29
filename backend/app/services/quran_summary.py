from typing import Protocol


class QuranWeeklyTargetStatus(Protocol):
    target_met: bool


def quran_completion_percent(pages_completed: int, target_pages: int) -> int:
    if target_pages <= 0:
        return 0
    return min(100, int(pages_completed / target_pages * 100))


def quran_current_streak(weekly_summary: list[QuranWeeklyTargetStatus]) -> int:
    streak = 0
    for item in reversed(weekly_summary):
        if not item.target_met:
            break
        streak += 1
    return streak
