import json
import logging
from types import SimpleNamespace

from app.core.logging import JSONFormatter
from app.core.middleware import RequestTimingMiddleware, SLOW_REQUEST_THRESHOLD_MS


def _request(path: str) -> SimpleNamespace:
    return SimpleNamespace(url=SimpleNamespace(path=path))


def test_request_timing_failure_area_classification():
    assert RequestTimingMiddleware._failure_area(_request("/api/v1/auth/me"), 401) == "auth"
    assert RequestTimingMiddleware._failure_area(_request("/api/v1/ai/parse-task"), 500) == "ai_service"
    assert RequestTimingMiddleware._failure_area(_request("/api/v1/voice/transcribe"), 429) == "ai_service"
    assert RequestTimingMiddleware._failure_area(_request("/api/v1/scheduling/schedule"), 400) == "sync"
    assert (
        RequestTimingMiddleware._failure_area(
            _request("/api/v1/reminders/task"), 500
        )
        == "notification_scheduling"
    )
    assert RequestTimingMiddleware._failure_area(_request("/api/v1/tasks"), 200) is None


def test_json_formatter_includes_request_timing_fields():
    record = logging.LogRecord(
        name="test",
        level=logging.WARNING,
        pathname=__file__,
        lineno=1,
        msg="Slow API request",
        args=(),
        exc_info=None,
    )
    record.endpoint = "/api/v1/tasks"
    record.method = "GET"
    record.status_code = 200
    record.duration_ms = SLOW_REQUEST_THRESHOLD_MS + 1
    record.slow_threshold_ms = SLOW_REQUEST_THRESHOLD_MS

    payload = json.loads(JSONFormatter().format(record))

    assert payload["endpoint"] == "/api/v1/tasks"
    assert payload["method"] == "GET"
    assert payload["duration_ms"] == 1001
    assert payload["slow_threshold_ms"] == 1000
