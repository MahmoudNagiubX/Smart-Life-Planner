from datetime import date

import pytest

from app.schemas.note import NoteActionExtractionItem, NoteActionExtractionResponse
from app.services.note_action_extraction_service import (
    fallback_note_action_extraction,
    normalize_note_action_extraction,
)


def test_action_item_requires_confirmation():
    with pytest.raises(ValueError):
        NoteActionExtractionItem(
            item_type="task",
            title="Submit report",
            confidence="medium",
            reason="Action wording detected.",
            requires_confirmation=False,
        )


def test_action_response_accepts_supported_item_contract():
    response = NoteActionExtractionResponse(
        extracted_items=[
            NoteActionExtractionItem(
                item_type="REMINDER",
                title="Submit report",
                reminder_time="2026-05-01T20:00:00+00:00",
                confidence="HIGH",
                reason="Time language detected.",
            )
        ]
    )

    item = response.extracted_items[0]
    assert response.requires_confirmation is True
    assert item.item_type == "reminder"
    assert item.confidence == "high"
    assert item.reminder_time is not None


def test_fallback_extracts_demo_sentence_actions():
    response = fallback_note_action_extraction(
        "Submit report tomorrow at 8 PM and buy notebooks",
        date(2026, 4, 30),
    )

    titles = [item["title"] for item in response["extracted_items"]]
    assert "Submit report" in titles
    assert "buy notebooks" in titles
    assert response["requires_confirmation"] is True
    assert response["fallback_used"] is True
    first = response["extracted_items"][0]
    assert first["due_date"] == "2026-05-01T20:00:00+00:00"
    assert first["reminder_time"] == "2026-05-01T20:00:00+00:00"


def test_normalize_action_extraction_hardens_ai_output():
    response = normalize_note_action_extraction(
        {
            "extracted_items": [
                {
                    "item_type": "delete_note",
                    "title": "Call Ahmed",
                    "confidence": "certain",
                    "reason": "",
                    "requires_confirmation": False,
                },
                {"item_type": "task", "title": ""},
            ],
            "safety_notes": "Review first.",
        }
    )

    assert len(response["extracted_items"]) == 1
    item = response["extracted_items"][0]
    assert item["item_type"] == "task"
    assert item["confidence"] == "low"
    assert item["requires_confirmation"] is True
    assert response["safety_notes"] == "Review first."
