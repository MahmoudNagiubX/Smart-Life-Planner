import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone

from app.services.focus_recommendation import (
    apply_ai_focus_explanation,
    build_focus_recommendation,
)


@dataclass
class FocusTask:
    title: str
    priority: str = "medium"
    due_at: datetime | None = None
    estimated_minutes: int | None = None
    energy_required: str = "medium"
    is_splittable: bool = False
    id: uuid.UUID = field(default_factory=uuid.uuid4)


def test_focus_recommendation_prioritizes_high_priority_due_soon_task():
    now = datetime(2026, 5, 10, 9, tzinfo=timezone.utc)
    urgent = FocusTask(
        id=uuid.uuid4(),
        title="Submit project report",
        priority="high",
        due_at=now + timedelta(hours=6),
        estimated_minutes=25,
    )
    later = FocusTask(
        id=uuid.uuid4(),
        title="Read optional article",
        priority="low",
        due_at=now + timedelta(days=5),
        estimated_minutes=20,
    )

    result = build_focus_recommendation(
        [later, urgent],
        default_duration_minutes=25,
        now=now,
    )

    assert result["task_id"] == str(urgent.id)
    assert result["recommended_duration_minutes"] == 25
    assert "high priority" in result["reasons"]
    assert "due within 24 hours" in result["reasons"]
    assert result["confidence"] == "high"
    assert result["fallback_used"] is True


def test_focus_recommendation_returns_safe_empty_state():
    result = build_focus_recommendation([], default_duration_minutes=30)

    assert result["task_id"] is None
    assert result["title"] is None
    assert result["recommended_duration_minutes"] == 30
    assert result["confidence"] == "high"


def test_ai_explanation_marks_fallback_false_without_changing_task():
    task_id = str(uuid.uuid4())
    recommendation = {
        "task_id": task_id,
        "title": "Study chapter",
        "recommended_duration_minutes": 25,
        "reasons": ["high priority"],
        "confidence": "medium",
        "fallback_used": True,
        "explanation": "Recommended for 25 minutes.",
    }

    result = apply_ai_focus_explanation(
        recommendation,
        "Start here because it is urgent and focused.",
    )

    assert result["task_id"] == task_id
    assert result["fallback_used"] is False
    assert result["explanation"] == "Start here because it is urgent and focused."
