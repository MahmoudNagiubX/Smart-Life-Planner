"""Email delivery for auth codes with an explicit development fallback."""
from __future__ import annotations

import asyncio
import logging
import smtplib
from dataclasses import dataclass
from email.message import EmailMessage

from fastapi import HTTPException, status

from app.core.config import settings

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class EmailSendResult:
    sent: bool
    development_code: str | None = None
    development_message: str | None = None


async def send_verification_email(email: str, code: str) -> EmailSendResult:
    return await _send_code_email(
        email=email,
        code=code,
        subject="Verify your Smart Life Planner email",
        intro="Use this code to verify your Smart Life Planner account:",
        purpose="email_verification",
    )


async def send_password_reset_email(email: str, code: str) -> EmailSendResult:
    return await _send_code_email(
        email=email,
        code=code,
        subject="Reset your Smart Life Planner password",
        intro="Use this code to reset your Smart Life Planner password:",
        purpose="password_reset",
    )


async def _send_code_email(
    *,
    email: str,
    code: str,
    subject: str,
    intro: str,
    purpose: str,
) -> EmailSendResult:
    if not _smtp_configured():
        if _development_mode():
            logger.warning(
                "Development email fallback active purpose=%s recipient=%s code=%s",
                purpose,
                email,
                code,
            )
            return EmailSendResult(
                sent=False,
                development_code=code,
                development_message=(
                    "Email is not configured. Development code is shown for testing."
                ),
            )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Email delivery is not configured. Please contact support.",
        )

    message = _build_message(email=email, subject=subject, intro=intro, code=code)
    try:
        await asyncio.to_thread(_send_smtp_message, message)
    except Exception as exc:
        logger.exception(
            "Email delivery failed purpose=%s recipient=%s", purpose, email
        )
        if _development_mode():
            return EmailSendResult(
                sent=False,
                development_code=code,
                development_message=(
                    "Email delivery failed. Development code is shown for testing."
                ),
            )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not send email right now. Please try again.",
        ) from exc

    logger.info("Email sent purpose=%s recipient=%s", purpose, email)
    return EmailSendResult(sent=True)


def _smtp_configured() -> bool:
    return bool(settings.SMTP_HOST and settings.SMTP_FROM_EMAIL)


def _development_mode() -> bool:
    return settings.ENVIRONMENT.lower() in {"development", "dev", "debug", "local"}


def _build_message(
    *, email: str, subject: str, intro: str, code: str
) -> EmailMessage:
    message = EmailMessage()
    from_name = settings.SMTP_FROM_NAME.strip()
    from_email = settings.SMTP_FROM_EMAIL.strip()
    message["From"] = f"{from_name} <{from_email}>" if from_name else from_email
    message["To"] = email
    message["Subject"] = subject
    message.set_content(
        f"{intro}\n\n{code}\n\nThis code expires in 15 minutes."
    )
    return message


def _send_smtp_message(message: EmailMessage) -> None:
    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as smtp:
        if settings.SMTP_USE_TLS:
            smtp.starttls()
        if settings.SMTP_USERNAME:
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        smtp.send_message(message)
