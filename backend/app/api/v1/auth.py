import uuid
import random
import string
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.dependencies import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
)
from app.models.verification import EmailVerification, PasswordReset
from app.repositories.user_repository import (
    get_user_by_email,
    create_user,
    get_user_by_id,
    get_user_by_provider,
)
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserResponse,
    TokenResponse,
    VerifyEmailRequest,
    ResendVerificationRequest,
    ForgotPasswordRequest,
    VerifyResetCodeRequest,
    SetNewPasswordRequest,
    ChangePasswordRequest,
    GoogleSignInRequest,
)
from app.services.email_service import (
    send_verification_email,
    send_password_reset_email,
)
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.config import settings as app_settings
from app.core.logging import logger
from jose import jwt as jose_jwt
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

router = APIRouter(prefix="/auth", tags=["auth"])
bearer_scheme = HTTPBearer()

# ── helpers ────────────────────────────────────────────────────────────────

def _generate_code(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


async def _create_verification_code(
    db: AsyncSession, user_id: uuid.UUID
) -> str:
    code = _generate_code()
    expires = datetime.now(timezone.utc) + timedelta(minutes=15)
    verification = EmailVerification(
        user_id=user_id, code=code, expires_at=expires
    )
    db.add(verification)
    await db.commit()
    return code


# ── dependency ─────────────────────────────────────────────────────────────

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
):
    token = credentials.credentials
    user_id = decode_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    user = await get_user_by_id(db, uuid.UUID(user_id))
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )
    return user


# ── endpoints ──────────────────────────────────────────────────────────────

@router.post(
    "/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED
)
async def register(payload: UserRegister, db: AsyncSession = Depends(get_db)):
    existing = await get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Email already registered"
        )
    user = await create_user(
        db,
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
    )
    # Generate + send verification code
    code = await _create_verification_code(db, user.id)
    await send_verification_email(user.email, code)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, payload.email)
    if not user or not user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    if not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)


@router.post("/verify-email", status_code=status.HTTP_200_OK)
async def verify_email(
    payload: VerifyEmailRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.is_verified:
        return {"message": "Email already verified"}

    # Find the latest unused, unexpired code for this user
    result = await db.execute(
        select(EmailVerification)
        .where(
            EmailVerification.user_id == user.id,
            EmailVerification.used_at.is_(None),
            EmailVerification.expires_at > datetime.now(timezone.utc),
        )
        .order_by(EmailVerification.created_at.desc())
        .limit(1)
    )
    verification = result.scalar_one_or_none()

    if not verification or verification.code != payload.code:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    # Mark code used + verify user
    verification.used_at = datetime.now(timezone.utc)
    user.is_verified = True
    await db.commit()

    return {"message": "Email verified successfully"}


@router.post("/resend-verification", status_code=status.HTTP_200_OK)
async def resend_verification(
    payload: ResendVerificationRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    if not user:
        # Don't reveal if email exists — always return 200
        return {"message": "If that email exists, a code was sent"}

    if user.is_verified:
        return {"message": "Email already verified"}

    # Rate-limit: max 1 code per 60 seconds
    result = await db.execute(
        select(EmailVerification)
        .where(
            EmailVerification.user_id == user.id,
            EmailVerification.created_at
            > datetime.now(timezone.utc) - timedelta(seconds=60),
        )
        .limit(1)
    )
    recent = result.scalar_one_or_none()
    if recent:
        raise HTTPException(
            status_code=429, detail="Please wait before requesting another code"
        )

    code = await _create_verification_code(db, user.id)
    await send_verification_email(user.email, code)
    return {"message": "If that email exists, a code was sent"}


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(
    payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    # Always return 200 — never reveal if email exists
    if not user or not user.is_active:
        return {"message": "If that email exists, a reset code was sent"}

    # Rate-limit: 1 code per 60 seconds
    result = await db.execute(
        select(PasswordReset).where(
            PasswordReset.user_id == user.id,
            PasswordReset.created_at > datetime.now(timezone.utc) - timedelta(seconds=60),
        ).limit(1)
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=429, detail="Please wait before requesting another code")

    code = _generate_code()
    expires = datetime.now(timezone.utc) + timedelta(minutes=15)
    reset = PasswordReset(user_id=user.id, code=code, expires_at=expires)
    db.add(reset)
    await db.commit()

    await send_password_reset_email(user.email, code)
    return {"message": "If that email exists, a reset code was sent"}


@router.post("/verify-reset-code", status_code=status.HTTP_200_OK)
async def verify_reset_code(
    payload: VerifyResetCodeRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    if not user:
        raise HTTPException(status_code=400, detail="Invalid code")

    result = await db.execute(
        select(PasswordReset).where(
            PasswordReset.user_id == user.id,
            PasswordReset.code == payload.code,
            PasswordReset.used_at.is_(None),
            PasswordReset.reset_token.is_(None),
            PasswordReset.expires_at > datetime.now(timezone.utc),
        ).order_by(PasswordReset.created_at.desc()).limit(1)
    )
    reset = result.scalar_one_or_none()
    if not reset:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    # Issue a one-time reset token
    reset_token = "".join(
        random.choices(string.ascii_letters + string.digits, k=64)
    )
    reset.reset_token = reset_token
    await db.commit()

    return {"reset_token": reset_token}


@router.post("/set-new-password", status_code=status.HTTP_200_OK)
async def set_new_password(
    payload: SetNewPasswordRequest, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PasswordReset).where(
            PasswordReset.reset_token == payload.reset_token,
            PasswordReset.used_at.is_(None),
            PasswordReset.expires_at > datetime.now(timezone.utc),
        ).limit(1)
    )
    reset = result.scalar_one_or_none()
    if not reset:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")

    user = await get_user_by_id(db, reset.user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=400, detail="Invalid request")

    # Set new password + mark token used
    user.hashed_password = hash_password(payload.new_password)
    reset.used_at = datetime.now(timezone.utc)
    await db.commit()

    return {"message": "Password updated successfully"}


@router.post("/google", response_model=TokenResponse)
async def google_sign_in(
    payload: GoogleSignInRequest, db: AsyncSession = Depends(get_db)
):
    if not app_settings.GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Google sign-in not configured")

    # Verify the Google ID token
    try:
        id_info = google_id_token.verify_oauth2_token(
            payload.id_token,
            google_requests.Request(),
            app_settings.GOOGLE_CLIENT_ID,
        )
    except ValueError as exc:
        try:
            claims = jose_jwt.get_unverified_claims(payload.id_token)
            logger.warning(
                "Invalid Google token: %s | expected_aud=%s actual_aud=%s issuer=%s email=%s",
                exc,
                app_settings.GOOGLE_CLIENT_ID,
                claims.get("aud"),
                claims.get("iss"),
                claims.get("email"),
            )
        except Exception:
            logger.warning(
                "Invalid Google token: %s | expected_aud=%s | could not decode claims",
                exc,
                app_settings.GOOGLE_CLIENT_ID,
            )
        raise HTTPException(
            status_code=400,
            detail="Invalid Google token. Check that Flutter uses the Web OAuth client ID and backend GOOGLE_CLIENT_ID matches it.",
        )

    google_user_id = id_info["sub"]
    email = id_info.get("email", "")
    full_name = id_info.get("name", email.split("@")[0])
    email_verified = id_info.get("email_verified", False)

    if not email:
        raise HTTPException(status_code=400, detail="Google account has no email")

    # Check if user exists by Google provider ID
    from app.models.user import AuthProvider
    user = await get_user_by_provider(db, AuthProvider.google, google_user_id)

    if not user:
        # Check if email already registered with a different provider
        existing = await get_user_by_email(db, email)
        if existing and existing.auth_provider != AuthProvider.google:
            raise HTTPException(
                status_code=409,
                detail="An account with this email already exists. Please sign in with email/password.",
            )
        # Create new Google user
        user = await create_user(
            db,
            email=email,
            full_name=full_name,
            hashed_password=None,
            auth_provider=AuthProvider.google,
            provider_user_id=google_user_id,
            is_verified=email_verified,
        )

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)


@router.post("/change-password", status_code=status.HTTP_200_OK)
async def change_password(
    payload: ChangePasswordRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Google/Apple users have no password to change
    if not current_user.hashed_password:
        raise HTTPException(
            status_code=400,
            detail="Password change is not available for social login accounts",
        )
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    if payload.current_password == payload.new_password:
        raise HTTPException(
            status_code=400, detail="New password must be different from current"
        )

    current_user.hashed_password = hash_password(payload.new_password)
    await db.commit()
    return {"message": "Password changed successfully"}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user=Depends(get_current_user)):
    return current_user
