import uuid
from datetime import datetime

from app.core.logging import logger


def _safe_datetime(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def log_task_reminders_cancelled(
    *,
    user_id: uuid.UUID,
    task_id: uuid.UUID,
    reason: str,
) -> None:
    logger.info(
        "Task reminders cancelled",
        extra={
            "failure_area": "notification_scheduling",
            "safe_context": f"task_reminder_cancelled:{reason}",
            "user_id": str(user_id),
            "target_type": "task",
            "target_id": str(task_id),
        },
    )


def log_task_reminders_rescheduled(
    *,
    user_id: uuid.UUID,
    task_id: uuid.UUID,
    previous_due_at: datetime | None,
    previous_reminder_at: datetime | None,
    next_due_at: datetime | None,
    next_reminder_at: datetime | None,
) -> None:
    logger.info(
        "Task reminders rescheduled",
        extra={
            "failure_area": "notification_scheduling",
            "safe_context": "task_due_or_reminder_changed",
            "user_id": str(user_id),
            "target_type": "task",
            "target_id": str(task_id),
            "previous_due_at": _safe_datetime(previous_due_at),
            "previous_reminder_at": _safe_datetime(previous_reminder_at),
            "next_due_at": _safe_datetime(next_due_at),
            "next_reminder_at": _safe_datetime(next_reminder_at),
        },
    )


def log_habit_reminders_cancelled(
    *,
    user_id: uuid.UUID,
    habit_id: uuid.UUID,
    reason: str,
) -> None:
    logger.info(
        "Habit reminders cancelled",
        extra={
            "failure_area": "notification_scheduling",
            "safe_context": f"habit_reminder_cancelled:{reason}",
            "user_id": str(user_id),
            "target_type": "habit",
            "target_id": str(habit_id),
        },
    )


def log_prayer_reminders_invalidated(
    *,
    user_id: uuid.UUID,
    reason: str,
) -> None:
    logger.info(
        "Prayer reminders invalidated",
        extra={
            "failure_area": "notification_scheduling",
            "safe_context": f"prayer_reminders_invalidated:{reason}",
            "user_id": str(user_id),
            "target_type": "prayer",
        },
    )
