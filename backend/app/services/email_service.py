"""
Email service — dev mode logs to console.
Swap send_verification_email() body for real SMTP/SendGrid later.
"""
import logging

logger = logging.getLogger(__name__)


async def send_verification_email(email: str, code: str) -> None:
    """
    In production: send a real email via SMTP / SendGrid / Resend.
    In development: log the code so you can copy it from terminal.
    """
    logger.info(
        f"[DEV] Verification code for {email}: {code}  "
        "(Replace this with real email sending in production)"
    )


async def send_password_reset_email(email: str, code: str) -> None:
    """
    Placeholder for password reset email — used in Step 12A.3.
    """
    logger.info(
        f"[DEV] Password reset code for {email}: {code}  "
        "(Replace this with real email sending in production)"
    )