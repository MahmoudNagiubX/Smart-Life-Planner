from app.services.quick_capture_classifier import classify_quick_capture


def test_classifies_checklist_input():
    result = classify_quick_capture("- buy milk\n- call mom")

    assert result["capture_type"] == "checklist"
    assert result["confidence"] == "high"
    assert result["checklist_items"] == ["buy milk", "call mom"]


def test_classifies_reminder_input_with_time():
    result = classify_quick_capture("remind me to submit report tomorrow at 6 pm")

    assert result["capture_type"] == "reminder"
    assert result["reminder_at"] is not None
    assert "submit report" in result["title"]


def test_unclear_short_input_requires_manual_choice():
    result = classify_quick_capture("maybe")

    assert result["capture_type"] == "unclear"
    assert result["confidence"] == "low"
