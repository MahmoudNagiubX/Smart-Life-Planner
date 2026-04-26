"""
Email service — dev mode logs to console.
Swap send_verification_email() body for real SMTP/SendGrid later.
"""
import logging

logger = logging.getLogger(__name__)


async def send_verification_email(email: str, code: str) -> None:
    """
    In production: send a real email via SMTP / SendGrid / Resend.
    Codes are intentionally omitted from logs.
    """
    logger.info(
        "Verification email queued. Configure an email provider before production."
    )


async def send_password_reset_email(email: str, code: str) -> None:
    """
    Placeholder for password reset email — used in Step 12A.3.
    """
    logger.info(
        "Password reset email queued. Configure an email provider before production."
    )
