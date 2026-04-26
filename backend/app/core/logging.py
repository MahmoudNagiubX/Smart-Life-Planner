import json
import logging
import sys
from datetime import datetime, timezone
from typing import Any


SAFE_EXTRA_KEYS = {
    "request_id",
    "endpoint",
    "method",
    "status_code",
    "exception_type",
    "error_type",
    "fields",
    "safe_context",
    "duration_ms",
    "failure_area",
    "slow_threshold_ms",
    "user_id",
    "target_type",
    "target_id",
    "previous_due_at",
    "previous_reminder_at",
    "next_due_at",
    "next_reminder_at",
}

SENSITIVE_KEY_FRAGMENTS = {
    "authorization",
    "cookie",
    "password",
    "secret",
    "token",
    "code",
    "email",
    "audio",
    "transcript",
    "content",
    "journal",
    "note",
}

REDACTED_TEXT = "[redacted]"


def _is_sensitive_key(key: str) -> bool:
    lowered = key.lower()
    return any(fragment in lowered for fragment in SENSITIVE_KEY_FRAGMENTS)


def _json_safe(value: Any) -> Any:
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if isinstance(value, (list, tuple, set)):
        return [_json_safe(item) for item in value]
    if isinstance(value, dict):
        return {
            str(key): _json_safe(item)
            for key, item in value.items()
            if not _is_sensitive_key(str(key))
        }
    return str(value)


def redact_sensitive_text(value: str) -> str:
    redacted = value
    for fragment in SENSITIVE_KEY_FRAGMENTS:
        redacted = redacted.replace(fragment, REDACTED_TEXT)
        redacted = redacted.replace(fragment.upper(), REDACTED_TEXT)
        redacted = redacted.replace(fragment.title(), REDACTED_TEXT)
    return redacted


class JSONFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": redact_sensitive_text(record.getMessage()),
            "service": "smart-life-planner-api",
        }

        for key in SAFE_EXTRA_KEYS:
            if hasattr(record, key):
                payload[key] = _json_safe(getattr(record, key))

        if record.exc_info and "exception_type" not in payload:
            payload["exception_type"] = record.exc_info[0].__name__

        return json.dumps(payload, ensure_ascii=True, separators=(",", ":"))


def setup_logging() -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    root_logger.handlers.clear()
    root_logger.addHandler(handler)

    logging.getLogger("uvicorn.access").setLevel(logging.INFO)


logger = logging.getLogger("smart_life_planner")
