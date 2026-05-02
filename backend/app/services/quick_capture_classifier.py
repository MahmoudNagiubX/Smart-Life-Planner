import re
from datetime import datetime, time, timedelta, timezone


CAPTURE_TYPES = {"task", "note", "reminder", "checklist", "journal_entry", "unclear"}


def _clean_title(text: str) -> str:
    clean = re.sub(r"\s+", " ", text).strip(" -:\n\t")
    return clean[:120] or "Quick capture"


def _strip_prefix(text: str, prefixes: tuple[str, ...]) -> str:
    lowered = text.lower().strip()
    for prefix in prefixes:
        if lowered.startswith(prefix):
            return text[len(prefix) :].strip(" -:")
    return text


def _extract_checklist_items(text: str) -> list[str]:
    """Algorithm: Rule-Based Information Extraction
    Used for: Checklist item extraction from quick capture text.
    Complexity: O(n) over input lines/text.
    Notes: Detects list markers and comma-separated fallback items.
    """
    items: list[str] = []
    for line in text.splitlines():
        clean = re.sub(r"^\s*(?:[-*]|\d+[.)]|\[[ xX]\])\s*", "", line).strip()
        if clean:
            items.append(clean[:500])
    if len(items) <= 1 and "," in text:
        items = [part.strip()[:500] for part in text.split(",") if part.strip()]
    return items[:30]


def _extract_reminder_at(text: str) -> datetime | None:
    """Algorithm: Rule-Based Information Extraction
    Used for: Reminder time parsing in quick capture.
    Complexity: O(n) over the text pattern search.
    Notes: Extracts simple today/tomorrow and clock-time expressions.
    """
    now = datetime.now(timezone.utc)
    lowered = text.lower()
    base_date = now.date()
    if "tomorrow" in lowered:
        base_date = (now + timedelta(days=1)).date()
    elif "today" in lowered:
        base_date = now.date()

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

    reminder_at = datetime.combine(base_date, time(hour, minute), tzinfo=timezone.utc)
    if reminder_at <= now and "tomorrow" not in lowered:
        reminder_at += timedelta(days=1)
    return reminder_at


def classify_quick_capture(input_text: str) -> dict:
    """Algorithm: Rule-Based Classification
    Used for: Quick capture task/note/reminder/checklist/journal routing.
    Complexity: O(n) over the captured text.
    Notes: Uses deterministic text markers before saving anything.
    """
    text = input_text.strip()
    lowered = text.lower()
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    if len(text) <= 3 or lowered in {"thing", "stuff", "later", "maybe"}:
        return {
            "capture_type": "unclear",
            "confidence": "low",
            "title": _clean_title(text),
            "content": text,
            "checklist_items": [],
            "reminder_at": None,
            "reason": "Input is too short to classify safely.",
        }

    checklist_markers = sum(
        1 for line in lines if re.match(r"^\s*(?:[-*]|\d+[.)]|\[[ xX]\])\s+", line)
    )
    if "checklist" in lowered or checklist_markers >= 2:
        items = _extract_checklist_items(text)
        return {
            "capture_type": "checklist",
            "confidence": "high" if len(items) >= 2 else "medium",
            "title": "Checklist",
            "content": "\n".join(items) if items else text,
            "checklist_items": items,
            "reminder_at": None,
            "reason": "Multiple list items were detected.",
        }

    reminder_prefixes = ("remind me to", "remind me", "remember to", "ذكرني")
    if lowered.startswith(reminder_prefixes) or " reminder " in f" {lowered} ":
        reminder_at = _extract_reminder_at(text)
        title = _clean_title(_strip_prefix(text, reminder_prefixes))
        return {
            "capture_type": "reminder",
            "confidence": "high" if reminder_at else "medium",
            "title": title,
            "content": text,
            "checklist_items": [],
            "reminder_at": reminder_at,
            "reason": "Reminder language was detected.",
        }

    journal_markers = (
        "journal:",
        "reflection:",
        "today i feel",
        "today i felt",
        "i feel",
        "i felt",
        "dear diary",
    )
    if lowered.startswith(journal_markers) or any(marker in lowered for marker in journal_markers[2:]):
        return {
            "capture_type": "journal_entry",
            "confidence": "medium",
            "title": "Journal entry",
            "content": text,
            "checklist_items": [],
            "reminder_at": None,
            "reason": "Reflective journal-style wording was detected.",
        }

    task_prefixes = (
        "todo",
        "task",
        "finish",
        "complete",
        "submit",
        "call",
        "email",
        "pay",
        "buy",
        "study",
        "schedule",
        "work on",
    )
    if lowered.startswith(task_prefixes):
        title = _clean_title(_strip_prefix(text, ("todo", "task")))
        return {
            "capture_type": "task",
            "confidence": "medium",
            "title": title,
            "content": text,
            "checklist_items": [],
            "reminder_at": None,
            "reason": "Action-oriented task wording was detected.",
        }

    note_markers = ("idea", "note", "remember", "thought")
    if any(marker in lowered for marker in note_markers):
        return {
            "capture_type": "note",
            "confidence": "medium",
            "title": _clean_title(text),
            "content": text,
            "checklist_items": [],
            "reminder_at": None,
            "reason": "Note-style wording was detected.",
        }

    return {
        "capture_type": "unclear",
        "confidence": "low",
        "title": _clean_title(text),
        "content": text,
        "checklist_items": [],
        "reminder_at": None,
        "reason": "No strong deterministic capture pattern matched.",
    }
