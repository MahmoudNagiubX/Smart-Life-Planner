from datetime import date, timedelta


def focus_current_streak(focus_days: set[date], today: date) -> int:
    """Algorithm: Sequential Counting
    Used for: Current focus streak calculation.
    Complexity: O(s), where s is the current streak length.
    Notes: Walks backward day by day while completed focus days continue.
    """
    current = today
    if current not in focus_days and current - timedelta(days=1) in focus_days:
        current = current - timedelta(days=1)

    streak = 0
    while current in focus_days:
        streak += 1
        current = current - timedelta(days=1)
    return streak


def focus_longest_streak(focus_days: list[date]) -> int:
    """Algorithm: Sequential Counting
    Used for: Longest focus streak calculation.
    Complexity: O(n log n) because dates are sorted before scanning.
    Notes: Counts consecutive completed days and tracks the maximum run.
    """
    longest = 0
    running = 0
    previous_day: date | None = None

    for focus_day in sorted(focus_days):
        if previous_day and focus_day == previous_day + timedelta(days=1):
            running += 1
        else:
            running = 1
        longest = max(longest, running)
        previous_day = focus_day

    return longest


def focus_completion_rate(completed_sessions: int, closed_sessions: int) -> int:
    if closed_sessions <= 0:
        return 0
    return round((completed_sessions / closed_sessions) * 100)


def focus_report_summary(
    *,
    today_minutes: int,
    today_sessions: int,
    week_minutes: int,
    current_streak_days: int,
    completion_rate_percent: int,
) -> str:
    if today_sessions:
        return (
            f"Today: {today_minutes} minutes across {today_sessions} focus "
            f"session{'s' if today_sessions != 1 else ''}. Weekly total is "
            f"{week_minutes} minutes with a {completion_rate_percent}% "
            "completion rate."
        )
    if current_streak_days:
        label = "day" if current_streak_days == 1 else "days"
        return (
            f"Focus streak is active at {current_streak_days} {label}. "
            f"Weekly total is {week_minutes} minutes."
        )
    return "No completed focus sessions today yet."
