from app.schemas.voice import ParsedVoiceTask


TASK_INTENT = "bulk_task_capture"
SUPPORTED_NON_TASK_INTENTS = {
    "start_focus_session",
    "get_next_prayer",
    "get_daily_plan",
    "get_next_action",
}


def normalize_voice_task_parse(result: dict, fallback_text: str) -> dict:
    if not isinstance(result, dict):
        return voice_task_parse_fallback(fallback_text, "invalid_parse_result")

    detected_intent = result.get("detected_intent") or "unknown_intent"
    confidence = result.get("confidence")
    if confidence not in {"low", "medium", "high"}:
        confidence = "low"

    raw_tasks = result.get("tasks")
    tasks = raw_tasks if isinstance(raw_tasks, list) else []

    unsupported_intent = (
        detected_intent != TASK_INTENT
        and detected_intent not in SUPPORTED_NON_TASK_INTENTS
    )
    no_task_fallback = detected_intent == TASK_INTENT and not tasks
    confirmation_required = (
        result.get("confirmation_required", True)
        or confidence == "low"
        or unsupported_intent
        or no_task_fallback
    )

    if unsupported_intent:
        return voice_task_parse_fallback(fallback_text, "unsupported_intent")

    if no_task_fallback:
        return voice_task_parse_fallback(fallback_text, "no_tasks_detected")

    return {
        "detected_intent": detected_intent,
        "confidence": confidence,
        "tasks": tasks,
        "confirmation_required": confirmation_required,
        "requires_confirmation": confirmation_required,
        "display_text": result.get("display_text") or "Review before saving.",
        "fallback_reason": result.get("fallback_reason"),
    }


def voice_task_parse_fallback(transcribed_text: str, reason: str) -> dict:
    title = transcribed_text.strip()
    tasks = []
    if title:
        tasks = [
            ParsedVoiceTask(
                title=title,
                priority="medium",
            ).model_dump()
        ]

    return {
        "detected_intent": "manual_task_fallback",
        "confidence": "low",
        "tasks": tasks,
        "confirmation_required": True,
        "requires_confirmation": True,
        "display_text": "Could not parse this safely. Review or edit manually.",
        "fallback_reason": reason,
    }
