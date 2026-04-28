import pytest
from pydantic import ValidationError

from app.schemas.task import TaskCreate, TaskUpdate
from app.services.ai_fallback import parse_task_response


def test_task_create_accepts_gtd_status_buckets():
    assert TaskCreate(title="Clarify inbox item").status == "pending"
    assert TaskCreate(title="Call supplier", status="waiting").status == "waiting"
    assert TaskCreate(title="Future idea", status="someday").status == "someday"
    assert TaskUpdate(status="next").status == "next"


def test_task_create_rejects_completed_and_unknown_status():
    with pytest.raises(ValidationError):
        TaskCreate(title="Done already", status="completed")

    with pytest.raises(ValidationError):
        TaskUpdate(status="archive")


def test_ai_parse_response_suggests_gtd_bucket():
    scheduled = parse_task_response(
        "submit assignment tomorrow",
        {
            "title": "Submit assignment",
            "priority": "high",
            "due_at": "2026-04-29T09:00:00",
            "confidence": "high",
        },
    )
    waiting = parse_task_response(
        "waiting for advisor feedback",
        {"title": "Waiting for advisor feedback", "confidence": "medium"},
    )
    someday = parse_task_response(
        "future idea for portfolio site",
        {"title": "Future idea for portfolio site", "confidence": "medium"},
    )

    assert scheduled.data["gtd_bucket"] == "calendar"
    assert waiting.data["gtd_bucket"] == "waiting"
    assert someday.data["gtd_bucket"] == "someday"
