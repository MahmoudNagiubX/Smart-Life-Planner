from app.services.ai_fallback import parse_task_fallback, parse_task_response


def test_parse_task_response_requires_confirmation_for_low_confidence():
    response = parse_task_response(
        "maybe finish report sometime",
        {
            "title": "Finish report",
            "priority": "medium",
            "confidence": "low",
        },
    )

    assert response.success is True
    assert response.requires_confirmation is True
    assert response.parse_status == "uncertain"
    assert response.fallback_reason == "low_confidence"
    assert response.data["title"] == "Finish report"


def test_parse_task_response_sanitizes_incomplete_parse():
    response = parse_task_response(
        "review project tomorrow",
        {"priority": "urgent", "confidence": "unknown"},
    )

    assert response.success is True
    assert response.requires_confirmation is True
    assert response.data["title"] == "review project tomorrow"
    assert response.data["priority"] == "medium"
    assert response.data["confidence"] == "low"


def test_parse_task_fallback_is_safe_and_editable():
    response = parse_task_fallback("call Ahmed", "ai_service_failure")

    assert response.success is False
    assert response.requires_confirmation is True
    assert response.parse_status == "failed"
    assert response.fallback_reason == "ai_service_failure"
    assert response.data["title"] == "call Ahmed"
    assert response.data["priority"] == "medium"
