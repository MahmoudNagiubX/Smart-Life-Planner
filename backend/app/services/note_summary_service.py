import re

from app.models.note import Note


MAX_NOTE_SUMMARY_INPUT_CHARS = 12000


def build_note_summary_source(note: Note) -> str:
    """Algorithm: Aggregation
    Used for: Building a note summary source from title, content, and blocks.
    Complexity: O(n) over checklist and structured block items.
    Notes: Combines scattered note fields into one bounded summary input.
    """
    parts: list[str] = []
    if note.title:
        parts.append(f"Title: {note.title.strip()}")
    if note.content:
        parts.append(note.content.strip())

    checklist_items = note.checklist_items or []
    if checklist_items:
        checklist_text = [
            str(item.get("text", "")).strip()
            for item in checklist_items
            if isinstance(item, dict) and str(item.get("text", "")).strip()
        ]
        if checklist_text:
            parts.append("Checklist:\n" + "\n".join(f"- {item}" for item in checklist_text))

    structured_blocks = note.structured_blocks or []
    block_text: list[str] = []
    for block in structured_blocks:
        if not isinstance(block, dict):
            continue
        text = str(block.get("text", "")).strip()
        if text:
            block_text.append(text)
        items = block.get("items")
        if isinstance(items, list):
            for item in items:
                if isinstance(item, dict):
                    item_text = str(item.get("text", "")).strip()
                else:
                    item_text = str(item).strip()
                if item_text:
                    block_text.append(item_text)
    if block_text:
        parts.append("Blocks:\n" + "\n".join(block_text))

    source = "\n\n".join(part for part in parts if part).strip()
    return source[:MAX_NOTE_SUMMARY_INPUT_CHARS]


def fallback_note_summary(note_text: str, summary_style: str) -> dict:
    """Algorithm: Rule-Based Summarization Heuristic
    Used for: Deterministic note summaries when AI is unavailable.
    Complexity: O(n) over note text.
    Notes: Splits sentences and selects a short style-specific summary.
    """
    clean_text = _compact_whitespace(note_text)
    sentences = _split_sentences(clean_text)
    selected = sentences[:4] if sentences else [clean_text[:280]]
    selected = [sentence for sentence in selected if sentence]

    if summary_style == "bullets":
        summary = "\n".join(f"- {sentence}" for sentence in selected[:5])
    elif summary_style == "study_notes":
        summary = _study_notes_fallback(selected)
    elif summary_style == "action_focused":
        summary = _action_focused_fallback(selected)
    else:
        summary = " ".join(selected[:2]).strip()

    if not summary:
        summary = "This note needs more content before it can be summarized."

    return {
        "summary": summary[:2000],
        "confidence": "low",
        "fallback_used": True,
        "safety_notes": "AI summary unavailable; deterministic fallback generated. Review before inserting.",
    }


def normalize_note_summary_result(result: dict, fallback_used: bool = False) -> dict:
    """Algorithm: Fault-Tolerant / Defensive Parsing
    Used for: AI note summary normalization.
    Complexity: O(1)
    Notes: Ensures summary, confidence, fallback, and safety fields are safe.
    """
    if not isinstance(result, dict):
        return fallback_note_summary("", "short")

    summary = str(result.get("summary") or "").strip()
    if not summary:
        return fallback_note_summary("", "short")

    confidence = str(result.get("confidence") or "low").strip().lower()
    if confidence not in {"high", "medium", "low"}:
        confidence = "low"

    safety_notes = result.get("safety_notes")
    if safety_notes is not None:
        safety_notes = str(safety_notes).strip() or None

    return {
        "summary": summary[:4000],
        "confidence": confidence,
        "fallback_used": fallback_used,
        "safety_notes": safety_notes or "Review before inserting. Nothing was saved automatically.",
    }


def _compact_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def _split_sentences(value: str) -> list[str]:
    if not value:
        return []
    candidates = re.split(r"(?<=[.!?])\s+", value)
    if len(candidates) == 1:
        candidates = [part.strip() for part in value.split("\n") if part.strip()]
    return [candidate.strip(" -") for candidate in candidates if candidate.strip(" -")]


def _study_notes_fallback(sentences: list[str]) -> str:
    main_idea = sentences[0] if sentences else "Review the original note."
    details = sentences[1:4]
    lines = [f"Key idea: {main_idea}"]
    lines.extend(f"Review point: {detail}" for detail in details)
    return "\n".join(lines)


def _action_focused_fallback(sentences: list[str]) -> str:
    action_words = ("call", "email", "send", "finish", "review", "study", "prepare", "buy", "write", "complete")
    action_sentences = [
        sentence
        for sentence in sentences
        if any(word in sentence.lower() for word in action_words)
    ]
    if not action_sentences:
        return "No clear action items were found. Review the note manually."
    return "\n".join(f"- {sentence}" for sentence in action_sentences[:5])
