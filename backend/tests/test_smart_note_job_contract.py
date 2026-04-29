import uuid
from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from app.schemas.note import (
    SmartNoteJobCreate,
    SmartNoteJobResponse,
    SmartNoteJobUpdate,
)


@pytest.mark.parametrize(
    "job_type",
    ["ocr", "handwriting", "summary", "action_extraction"],
)
def test_smart_note_job_create_accepts_supported_types(job_type):
    payload = SmartNoteJobCreate(note_id=uuid.uuid4(), job_type=job_type.upper())

    assert payload.job_type == job_type


def test_smart_note_job_create_rejects_unknown_type():
    with pytest.raises(ValidationError):
        SmartNoteJobCreate(note_id=uuid.uuid4(), job_type="auto_delete_note")


@pytest.mark.parametrize("status", ["pending", "processing", "completed", "failed"])
def test_smart_note_job_update_accepts_supported_statuses(status):
    payload = SmartNoteJobUpdate(status=status.upper())

    assert payload.status == status


def test_smart_note_job_response_serializes_safe_result_fields():
    now = datetime.now(timezone.utc)
    response = SmartNoteJobResponse(
        id=uuid.uuid4(),
        user_id=uuid.uuid4(),
        note_id=uuid.uuid4(),
        job_type="summary",
        status="completed",
        input_attachment_id=None,
        result_text="Short summary",
        result_json={"confidence": 0.82},
        error_code=None,
        created_at=now,
        completed_at=now,
    )

    dumped = response.model_dump()

    assert dumped["result_text"] == "Short summary"
    assert dumped["result_json"] == {"confidence": 0.82}
    assert dumped["status"] == "completed"
