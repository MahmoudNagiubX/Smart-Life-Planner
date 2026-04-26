import json
import logging

from app.core.logging import JSONFormatter


def test_json_formatter_outputs_safe_structured_payload():
    record = logging.LogRecord(
        name="test",
        level=logging.ERROR,
        pathname=__file__,
        lineno=1,
        msg="Password reset failed for token",
        args=(),
        exc_info=None,
    )
    record.request_id = "req-123"
    record.endpoint = "/api/v1/auth/set-new-password"
    record.exception_type = "RuntimeError"
    record.safe_context = "Unhandled exception converted to safe response"

    payload = json.loads(JSONFormatter().format(record))

    assert payload["timestamp"]
    assert payload["level"] == "ERROR"
    assert payload["request_id"] == "req-123"
    assert payload["endpoint"] == "/api/v1/auth/set-new-password"
    assert payload["exception_type"] == "RuntimeError"
    assert payload["safe_context"] == "Unhandled exception converted to safe response"
    assert "Password" not in payload["message"]
    assert "token" not in payload["message"]


def test_json_formatter_filters_sensitive_extra_fields():
    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="Request validation failed",
        args=(),
        exc_info=None,
    )
    record.fields = [
        {"field": "sensitive_field", "message": "Input should be valid"},
        {"field": "body -> title", "message": "Field required"},
    ]
    record.token = "secret-token"

    payload = json.loads(JSONFormatter().format(record))

    assert "token" not in payload
    assert payload["fields"][0]["field"] == "sensitive_field"
