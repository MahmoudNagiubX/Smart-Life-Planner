from app.services.voice_fallback import (
    normalize_voice_task_parse,
    voice_task_parse_fallback,
)


def test_voice_low_confidence_requires_confirmation():
    result = normalize_voice_task_parse(
        {
            "detected_intent": "bulk_task_capture",
            "confidence": "low",
            "tasks": [{"title": "Review project", "priority": "medium"}],
            "confirmation_required": False,
            "display_text": "Review your tasks.",
        },
        "review project",
    )

    assert result["confirmation_required"] is True
    assert result["requires_confirmation"] is True
    assert result["confidence"] == "low"


def test_voice_unsupported_intent_returns_manual_fallback():
    result = normalize_voice_task_parse(
        {
            "detected_intent": "unsupported_action",
            "confidence": "high",
            "tasks": [],
        },
        "do something unclear",
    )

    assert result["detected_intent"] == "manual_task_fallback"
    assert result["confirmation_required"] is True
    assert result["fallback_reason"] == "unsupported_intent"
    assert result["tasks"][0]["title"] == "do something unclear"


def test_voice_parse_fallback_is_structured_and_editable():
    result = voice_task_parse_fallback("create task tomorrow", "voice_parse_failure")

    assert result["confidence"] == "low"
    assert result["requires_confirmation"] is True
    assert result["tasks"][0]["title"] == "create task tomorrow"
