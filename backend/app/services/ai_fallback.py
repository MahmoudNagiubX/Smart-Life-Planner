from app.schemas.ai import ParseTaskResponse


def _suggest_gtd_bucket(data: dict) -> str:
    explicit_bucket = data.get("gtd_bucket")
    if explicit_bucket in {"inbox", "next", "waiting", "someday", "calendar"}:
        return explicit_bucket

    title = str(data.get("title") or "").lower()
    category = str(data.get("category") or "").lower()
    combined = f"{title} {category}"
    if data.get("due_at"):
        return "calendar"
    if any(word in combined for word in ("waiting", "blocked", "follow up")):
        return "waiting"
    if any(word in combined for word in ("someday", "maybe", "idea", "future")):
        return "someday"
    if data.get("priority") == "high":
        return "next"
    return "inbox"


def parse_task_fallback(raw_input: str, reason: str) -> ParseTaskResponse:
    return ParseTaskResponse(
        success=False,
        data={
            "title": raw_input,
            "priority": "medium",
            "due_at": None,
            "estimated_minutes": None,
            "category": None,
            "gtd_bucket": "inbox",
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
    data["gtd_bucket"] = _suggest_gtd_bucket(data)

    requires_confirmation = confidence == "low" or incomplete
    return ParseTaskResponse(
        success=True,
        data=data,
        raw_input=raw_input,
        requires_confirmation=requires_confirmation,
        parse_status="uncertain" if requires_confirmation else "parsed",
        fallback_reason="low_confidence" if requires_confirmation else None,
    )
