import uuid
from datetime import datetime, timezone

from app.models.task import Task
from app.repositories.task_repository import _task_completion_event
from app.schemas.task import TaskCompletionEventResponse


def test_task_completion_event_records_safe_status_transition():
    task = Task(id=uuid.uuid4(), user_id=uuid.uuid4(), title="Review plan")
    occurred_at = datetime.now(timezone.utc)

    event = _task_completion_event(
        task,
        event_type="completed",
        previous_status="pending",
        next_status="completed",
        occurred_at=occurred_at,
    )

    assert event.task_id == task.id
    assert event.user_id == task.user_id
    assert event.event_type == "completed"
    assert event.previous_status == "pending"
    assert event.next_status == "completed"
    assert event.occurred_at == occurred_at


def test_task_completion_event_response_serializes_reopen_event():
    event_id = uuid.uuid4()
    task_id = uuid.uuid4()
    occurred_at = datetime.now(timezone.utc)

    response = TaskCompletionEventResponse(
        id=event_id,
        task_id=task_id,
        event_type="reopened",
        previous_status="completed",
        next_status="pending",
        occurred_at=occurred_at,
        created_at=occurred_at,
    )

    assert response.event_type == "reopened"
    assert response.previous_status == "completed"
    assert response.next_status == "pending"
