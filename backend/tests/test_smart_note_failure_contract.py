from fastapi import HTTPException

from app.services.smart_note_errors import smart_note_error


def test_smart_note_error_returns_structured_safe_detail():
    error = smart_note_error(
        "smart_note_empty_content",
        "Add note content before summarizing.",
        manual_fallback="Write a manual summary in the note editor.",
    )

    assert isinstance(error, HTTPException)
    assert error.status_code == 400
    assert error.detail == {
        "code": "smart_note_empty_content",
        "message": "Add note content before summarizing.",
        "retryable": False,
        "manual_fallback": "Write a manual summary in the note editor.",
    }
