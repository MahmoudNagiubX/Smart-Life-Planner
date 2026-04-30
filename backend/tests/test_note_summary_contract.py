import pytest

from app.schemas.note import NoteSummaryRequest, NoteSummaryResponse
from app.services.note_summary_service import (
    fallback_note_summary,
    normalize_note_summary_result,
)


@pytest.mark.parametrize(
    "style",
    ["short", "bullets", "study_notes", "action_focused"],
)
def test_note_summary_request_accepts_supported_styles(style):
    payload = NoteSummaryRequest(summary_style=style.upper())
    assert payload.summary_style == style


def test_note_summary_request_rejects_unknown_style():
    with pytest.raises(ValueError):
        NoteSummaryRequest(summary_style="replace_original_note")


def test_note_summary_response_requires_safe_confidence():
    response = NoteSummaryResponse(
        summary="Review photosynthesis and write flashcards.",
        confidence="MEDIUM",
        fallback_used=False,
        safety_notes="Review before inserting.",
    )

    assert response.confidence == "medium"


def test_fallback_note_summary_marks_fallback_and_low_confidence():
    response = fallback_note_summary(
        "Read chapter one. Write flashcards. Review examples.",
        "bullets",
    )

    assert response["fallback_used"] is True
    assert response["confidence"] == "low"
    assert "- Read chapter one." in response["summary"]


def test_normalize_note_summary_result_hardens_ai_output():
    response = normalize_note_summary_result(
        {
            "summary": "Key points are ready.",
            "confidence": "certain",
            "safety_notes": "",
        }
    )

    assert response["summary"] == "Key points are ready."
    assert response["confidence"] == "low"
    assert response["fallback_used"] is False
    assert response["safety_notes"] == "Review before inserting. Nothing was saved automatically."
