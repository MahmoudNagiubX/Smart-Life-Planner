def next_completed_pomodoro_count(
    current_count: int | None,
    estimated_count: int | None,
) -> int:
    current = max(current_count or 0, 0)
    estimate = max(estimated_count or 0, 0)
    next_count = current + 1
    if estimate > 0:
        return min(next_count, estimate)
    return next_count
