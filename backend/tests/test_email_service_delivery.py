import pytest
from fastapi import HTTPException

from app.core.config import settings
from app.services.email_service import send_password_reset_email


@pytest.mark.asyncio
async def test_email_service_returns_development_code_without_smtp(monkeypatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(settings, "SMTP_HOST", "")
    monkeypatch.setattr(settings, "SMTP_FROM_EMAIL", "")

    result = await send_password_reset_email("person@example.com", "123456")

    assert result.sent is False
    assert result.development_code == "123456"


@pytest.mark.asyncio
async def test_email_service_returns_development_code_after_smtp_success(monkeypatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(settings, "SMTP_HOST", "smtp.example.com")
    monkeypatch.setattr(settings, "SMTP_FROM_EMAIL", "sender@example.com")
    monkeypatch.setattr(
        "app.services.email_service._send_smtp_message",
        lambda message: None,
    )

    result = await send_password_reset_email("person@example.com", "123456")

    assert result.sent is True
    assert result.development_code == "123456"


@pytest.mark.asyncio
async def test_email_service_fails_safely_without_smtp_in_production(monkeypatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(settings, "SMTP_HOST", "")
    monkeypatch.setattr(settings, "SMTP_FROM_EMAIL", "")

    with pytest.raises(HTTPException) as exc_info:
        await send_password_reset_email("person@example.com", "123456")

    assert exc_info.value.status_code == 503
    assert "123456" not in exc_info.value.detail
