import uuid

import pytest
from pydantic import ValidationError

from app.schemas.task import TaskReorderRequest


def test_task_reorder_request_accepts_unique_task_ids():
    task_ids = [uuid.uuid4(), uuid.uuid4()]

    payload = TaskReorderRequest(task_ids=task_ids)

    assert payload.task_ids == task_ids


def test_task_reorder_request_rejects_empty_list():
    with pytest.raises(ValidationError):
        TaskReorderRequest(task_ids=[])


def test_task_reorder_request_rejects_duplicates():
    task_id = uuid.uuid4()

    with pytest.raises(ValidationError):
        TaskReorderRequest(task_ids=[task_id, task_id])


def test_task_reorder_request_rejects_oversized_batches():
    task_ids = [uuid.uuid4() for _ in range(201)]

    with pytest.raises(ValidationError):
        TaskReorderRequest(task_ids=task_ids)
