from app.schemas.ai import ParseTaskResponse


def parse_task_fallback(raw_input: str, reason: str) -> ParseTaskResponse:
    return ParseTaskResponse(
        success=False,
        data={
            "title": raw_input,
            "priority": "medium",
            "due_at": None,
            "estimated_minutes": None,
            "category": None,
            "confidence": "low",
        },
        raw_input=raw_input,
        requires_confirmation=True,
        parse_status="failed",
        fallback_reason=reason,
    )


def parse_task_response(raw_input: str, result: dict) -> ParseTaskResponse:
    if not isinstance(result, dict):
        return parse_task_fallback(raw_input, "incomplete_parse")

    data = dict(result)
    title = data.get("title")
    incomplete = not isinstance(title, str) or not title.strip()
    if incomplete:
        data["title"] = raw_input
    else:
        data["title"] = title.strip()

    if data.get("priority") not in {"low", "medium", "high"}:
        data["priority"] = "medium"

    confidence = data.get("confidence")
    if confidence not in {"high", "medium", "low"}:
        confidence = "low"
    data["confidence"] = confidence

    data.setdefault("due_at", None)
    data.setdefault("estimated_minutes", None)
    data.setdefault("category", None)

    requires_confirmation = confidence == "low" or incomplete
    return ParseTaskResponse(
        success=True,
        data=data,
        raw_input=raw_input,
        requires_confirmation=requires_confirmation,
        parse_status="uncertain" if requires_confirmation else "parsed",
        fallback_reason="low_confidence" if requires_confirmation else None,
    )
