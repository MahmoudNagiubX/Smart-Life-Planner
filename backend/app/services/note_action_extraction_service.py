import re
from datetime import date, datetime, time, timedelta, timezone
from typing import Any


ALLOWED_ACTION_ITEM_TYPES = {
    "task",
    "reminder",
    "checklist_item",
    "calendar_suggestion",
    "focus_suggestion",
}
ALLOWED_CONFIDENCE = {"high", "medium", "low"}
ACTION_WORDS = (
    "submit",
    "buy",
    "call",
    "email",
    "send",
    "finish",
    "complete",
    "review",
    "study",
    "prepare",
    "write",
    "pay",
    "schedule",
)


def fallback_note_action_extraction(note_text: str, today: date) -> dict[str, Any]:
    items: list[dict[str, Any]] = []
    for clause in _candidate_clauses(note_text):
        item = _fallback_item_from_clause(clause, today)
        if item is not None:
            items.append(item)
        if len(items) >= 8:
            break

    return {
        "extracted_items": items,
        "requires_confirmation": True,
        "fallback_used": True,
        "safety_notes": "AI unavailable; deterministic suggestions generated. Review before creating.",
    }


def normalize_note_action_extraction(result: dict[str, Any]) -> dict[str, Any]:
    raw_items = result.get("extracted_items")
    if not isinstance(raw_items, list):
        raw_items = []

    items: list[dict[str, Any]] = []
    for raw_item in raw_items:
        normalized = _normalize_action_item(raw_item)
        if normalized is not None:
            items.append(normalized)
        if len(items) >= 8:
            break

    safety_notes = result.get("safety_notes")
    return {
        "extracted_items": items,
        "requires_confirmation": True,
        "fallback_used": bool(result.get("fallback_used", False)),
        "safety_notes": str(safety_notes).strip() if safety_notes else None,
    }


def _candidate_clauses(note_text: str) -> list[str]:
    normalized = re.sub(r"\s+", " ", note_text or "").strip()
    if not normalized:
        return []

    clauses = re.split(r"\s+(?:and|also|then)\s+|[;\n]+", normalized, flags=re.I)
    if len(clauses) == 1 and "," in normalized:
        clauses = normalized.split(",")
    return [clause.strip(" .:-") for clause in clauses if clause.strip(" .:-")]


def _fallback_item_from_clause(clause: str, today: date) -> dict[str, Any] | None:
    lowered = clause.lower()
    reminder_time = _extract_datetime(clause, today)
    checklist_like = lowered.startswith(("- ", "* ", "[ ]", "[x]"))
    action_like = lowered.startswith(ACTION_WORDS)
    reminder_like = lowered.startswith(("remind me", "remember to")) or reminder_time

    if not (checklist_like or action_like or reminder_like):
        return None

    title = _clean_action_title(clause)
    item_type = "reminder" if reminder_like and not action_like else "task"
    if checklist_like:
        item_type = "checklist_item"

    return {
        "item_type": item_type,
        "title": title,
        "due_date": reminder_time.isoformat() if reminder_time and item_type == "task" else None,
        "reminder_time": reminder_time.isoformat() if reminder_time else None,
        "confidence": "medium" if action_like or reminder_time else "low",
        "reason": "Detected action wording and/or time language.",
        "requires_confirmation": True,
    }


def _clean_action_title(value: str) -> str:
    clean = re.sub(r"\b(today|tomorrow)\b", "", value, flags=re.I)
    clean = re.sub(r"\bat\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\b", "", clean, flags=re.I)
    clean = re.sub(r"^\s*(?:[-*]|\[[ xX]\])\s*", "", clean)
    clean = re.sub(r"\s+", " ", clean).strip(" .:-")
    return clean[:160] or "Action from note"


def _extract_datetime(value: str, today: date) -> datetime | None:
    lowered = value.lower()
    target_date = today
    if "tomorrow" in lowered:
        target_date = today + timedelta(days=1)
    elif "today" not in lowered and not re.search(r"\bat\s+\d", lowered):
        return None

    match = re.search(r"\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b", lowered)
    if not match:
        return None

    hour = int(match.group(1))
    minute = int(match.group(2) or "0")
    meridiem = match.group(3)
    if meridiem == "pm" and hour < 12:
        hour += 12
    if meridiem == "am" and hour == 12:
        hour = 0
    if hour > 23 or minute > 59:
        return None
    return datetime.combine(target_date, time(hour, minute), tzinfo=timezone.utc)


def _normalize_action_item(raw_item: Any) -> dict[str, Any] | None:
    if not isinstance(raw_item, dict):
        return None

    title = str(raw_item.get("title") or "").strip()
    if not title:
        return None

    item_type = str(raw_item.get("item_type") or "task").strip().lower()
    if item_type not in ALLOWED_ACTION_ITEM_TYPES:
        item_type = "task"

    confidence = str(raw_item.get("confidence") or "low").strip().lower()
    if confidence not in ALLOWED_CONFIDENCE:
        confidence = "low"

    reason = str(raw_item.get("reason") or "Suggested from note content.").strip()

    return {
        "item_type": item_type,
        "title": title[:160],
        "due_date": _normalize_datetime(raw_item.get("due_date")),
        "reminder_time": _normalize_datetime(raw_item.get("reminder_time")),
        "confidence": confidence,
        "reason": reason[:240],
        "requires_confirmation": True,
    }


def _normalize_datetime(value: Any) -> str | None:
    if value in (None, ""):
        return None
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, date):
        return datetime.combine(value, time(9, 0), tzinfo=timezone.utc).isoformat()
    text = str(value).strip()
    if not text:
        return None
    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.isoformat()
