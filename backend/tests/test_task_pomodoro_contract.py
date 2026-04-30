import pytest
from pydantic import ValidationError

from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate
from app.services.pomodoro_progress import next_completed_pomodoro_count


def test_task_schema_accepts_pomodoro_estimate():
    payload = TaskCreate(title="Study chapter", estimated_pomodoros=3)
    update = TaskUpdate(estimated_pomodoros=4, completed_pomodoros=1)

    assert payload.estimated_pomodoros == 3
    assert update.estimated_pomodoros == 4
    assert update.completed_pomodoros == 1


@pytest.mark.parametrize("value", [-1, 100])
def test_task_schema_rejects_invalid_pomodoro_estimate(value):
    with pytest.raises(ValidationError):
        TaskCreate(title="Bad estimate", estimated_pomodoros=value)


def test_task_response_exposes_pomodoro_progress(task_response_payload):
    response = TaskResponse(**task_response_payload)

    assert response.estimated_pomodoros == 3
    assert response.completed_pomodoros == 1


def test_completed_pomodoro_increment_caps_at_estimate():
    assert next_completed_pomodoro_count(0, 3) == 1
    assert next_completed_pomodoro_count(2, 3) == 3
    assert next_completed_pomodoro_count(3, 3) == 3
    assert next_completed_pomodoro_count(3, 0) == 4


@pytest.fixture
def task_response_payload():
    import uuid
    from datetime import datetime, timezone

    now = datetime(2026, 5, 1, 12, tzinfo=timezone.utc)
    return {
        "id": uuid.uuid4(),
        "user_id": uuid.uuid4(),
        "project_id": None,
        "title": "Study chapter",
        "description": None,
        "priority": "medium",
        "status": "pending",
        "due_at": None,
        "start_date": None,
        "reminder_at": None,
        "category": None,
        "estimated_minutes": None,
        "estimated_duration_minutes": None,
        "estimated_pomodoros": 3,
        "completed_pomodoros": 1,
        "manual_order": 0,
        "is_deleted": False,
        "completed_at": None,
        "created_at": now,
        "updated_at": now,
        "subtasks": [],
    }
