import uuid
import random
import secrets
import string
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt as jose_jwt, JWTError
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings as app_settings
from app.core.dependencies import get_db
from app.core.logging import logger
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
)
from app.models.user import AuthProvider
from app.models.verification import EmailVerification, PasswordReset
from app.repositories.user_repository import (
    get_user_by_email,
    create_user,
    get_user_by_id,
    get_user_by_provider,
)
from app.repositories.settings_repository import get_settings_by_user_id
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserResponse,
    RegisterResponse,
    TokenResponse,
    VerifyEmailRequest,
    ResendVerificationRequest,
    ForgotPasswordRequest,
    VerifyResetCodeRequest,
    SetNewPasswordRequest,
    ChangePasswordRequest,
    GoogleSignInRequest,
    AppleSignInRequest,
    DeleteAccountRequest,
)
from app.services.email_service import (
    EmailSendResult,
    send_verification_email,
    send_password_reset_email,
)

router = APIRouter(prefix="/auth", tags=["auth"])
bearer_scheme = HTTPBearer()

# ── Apple JWKS constants ────────────────────────────────────────────────────
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"
MAX_PASSWORD_RESET_ATTEMPTS = 5

# ── helpers ────────────────────────────────────────────────────────────────


def _generate_code(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def _generate_reset_token() -> str:
    return secrets.token_urlsafe(48)[:64]


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


def _code_sent_response(message: str, email_result: EmailSendResult) -> dict:
    response = {"message": message}
    if email_result.development_message:
        response["message"] = f"{message}. {email_result.development_message}"
    if email_result.development_code:
        response["development_code"] = email_result.development_code
    return response


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
    "/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED
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
    email_result = await send_verification_email(user.email, code)
    response = {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "auth_provider": user.auth_provider.value,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "onboarding_completed": False,
        "created_at": user.created_at,
        "message": "Account created. Check your email for the verification code.",
    }
    if email_result.development_message:
        response["message"] = (
            f"{response['message']} {email_result.development_message}"
        )
    if email_result.development_code:
        response["development_code"] = email_result.development_code
    return response


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, payload.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
        )
    if user.auth_provider != AuthProvider.email or not user.hashed_password:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This account uses social sign-in. Please use the original sign-in method.",
        )
    if not user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email before signing in.",
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
    email_result = await send_verification_email(user.email, code)
    return _code_sent_response(
        "If that email exists, a code was sent",
        email_result,
    )


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(
    payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    # Always return 200 — never reveal if email exists
    if not user or not user.is_active:
        return {"message": "If that email exists, a reset code was sent"}
    if user.auth_provider != AuthProvider.email or not user.hashed_password:
        logger.info(
            "Password reset requested for non-password account user_id=%s provider=%s",
            user.id,
            user.auth_provider.value,
        )
        return {"message": "If that email exists, a reset code was sent"}

    # Rate-limit: 1 code per 60 seconds
    result = await db.execute(
        select(PasswordReset).where(
            PasswordReset.user_id == user.id,
            PasswordReset.created_at
            > datetime.now(timezone.utc) - timedelta(seconds=60),
        ).limit(1)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=429, detail="Please wait before requesting another code"
        )

    code = _generate_code()
    expires = datetime.now(timezone.utc) + timedelta(minutes=15)
    reset = PasswordReset(user_id=user.id, code=code, expires_at=expires)
    db.add(reset)
    await db.commit()

    email_result = await send_password_reset_email(user.email, code)
    return _code_sent_response(
        "If that email exists, a reset code was sent",
        email_result,
    )


@router.post("/verify-reset-code", status_code=status.HTTP_200_OK)
async def verify_reset_code(
    payload: VerifyResetCodeRequest, db: AsyncSession = Depends(get_db)
):
    user = await get_user_by_email(db, payload.email)
    if (
        not user
        or user.auth_provider != AuthProvider.email
        or not user.hashed_password
    ):
        raise HTTPException(status_code=400, detail="Invalid code")

    result = await db.execute(
        select(PasswordReset).where(
            PasswordReset.user_id == user.id,
            PasswordReset.used_at.is_(None),
            PasswordReset.reset_token.is_(None),
            PasswordReset.expires_at > datetime.now(timezone.utc),
        ).order_by(PasswordReset.created_at.desc()).limit(1)
    )
    reset = result.scalar_one_or_none()
    if reset and reset.failed_attempts >= MAX_PASSWORD_RESET_ATTEMPTS:
        reset.used_at = datetime.now(timezone.utc)
        await db.commit()
        reset = None
    if not reset:
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    if reset.code != payload.code:
        reset.failed_attempts += 1
        if reset.failed_attempts >= MAX_PASSWORD_RESET_ATTEMPTS:
            reset.used_at = datetime.now(timezone.utc)
        await db.commit()
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    # Issue a one-time reset token
    reset_token = _generate_reset_token()
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
    if (
        not user
        or not user.is_active
        or user.auth_provider != AuthProvider.email
        or not user.hashed_password
    ):
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
            detail=(
                "Invalid Google token. Check that Flutter uses the Web OAuth "
                "client ID and backend GOOGLE_CLIENT_ID matches it."
            ),
        )

    google_user_id = id_info["sub"]
    email = id_info.get("email", "")
    full_name = id_info.get("name", email.split("@")[0])
    email_verified = id_info.get("email_verified", False)

    if not email:
        raise HTTPException(status_code=400, detail="Google account has no email")

    user = await get_user_by_provider(db, AuthProvider.google, google_user_id)

    if not user:
        # Check if email already registered with a different provider
        existing = await get_user_by_email(db, email)
        if existing:
            if existing.auth_provider == AuthProvider.google:
                logger.warning(
                    "Google sign-in provider mismatch for existing user_id=%s",
                    existing.id,
                )
                raise HTTPException(
                    status_code=409,
                    detail=(
                        "This email is already linked to another Google sign-in. "
                        "Please contact support."
                    ),
                )
            raise HTTPException(
                status_code=409,
                detail=(
                    "An account with this email already exists. "
                    "Please sign in with email/password."
                ),
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
async def get_me(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    settings = await get_settings_by_user_id(db, current_user.id)
    return {
        "id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "auth_provider": current_user.auth_provider.value,
        "is_active": current_user.is_active,
        "is_verified": current_user.is_verified,
        "created_at": current_user.created_at,
        "onboarding_completed": settings.onboarding_completed if settings else False,
    }


# ── Apple Sign-In ──────────────────────────────────────────────────────────
# Apple identity tokens are JWTs signed with Apple's private key.
# We verify them using Apple's published JWKS (public keys) — no additional
# library beyond python-jose (already in requirements.txt) is required.
#
# References:
#   https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/authenticating_users_with_sign_in_with_apple
#   https://appleid.apple.com/auth/keys


async def _fetch_apple_public_keys() -> list[dict]:
    """Fetch Apple's public JWKS. Returns list of JWK dicts."""
    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(APPLE_JWKS_URL)
        response.raise_for_status()
        data = response.json()
        return data.get("keys", [])


def _verify_apple_identity_token(
    identity_token: str,
    apple_keys: list[dict],
    audience: str,
) -> dict:
    """
    Verify an Apple identity token (JWT) against Apple's public keys.

    Returns the decoded claims dict if valid.
    Raises HTTPException 400 if invalid.

    Apple uses RS256 algorithm. The token header's `kid` identifies
    which public key to use from the JWKS response.
    """
    # 1. Read the unverified header to find the key ID
    try:
        unverified_header = jose_jwt.get_unverified_header(identity_token)
    except JWTError as exc:
        raise HTTPException(status_code=400, detail=f"Invalid Apple token header: {exc}")

    kid = unverified_header.get("kid")
    alg = unverified_header.get("alg")
    if alg != "RS256":
        raise HTTPException(
            status_code=400,
            detail="Apple token uses an unsupported signing algorithm",
        )

    # 2. Find the matching public key
    matching_key = next(
        (k for k in apple_keys if k.get("kid") == kid), None
    )
    if not matching_key:
        raise HTTPException(
            status_code=400,
            detail=f"Apple public key not found for kid={kid}. Try again shortly.",
        )

    # 3. Decode + verify signature, issuer, audience, and expiry
    try:
        claims = jose_jwt.decode(
            identity_token,
            matching_key,
            algorithms=["RS256"],
            audience=audience,
            issuer=APPLE_ISSUER,
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Apple token verification failed: {exc}",
        )

    return claims


@router.post("/apple", response_model=TokenResponse)
async def apple_sign_in(
    payload: AppleSignInRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Apple Sign-In endpoint.

    Flow:
    1. Verify Apple identity token using Apple JWKS.
    2. Extract sub (Apple user ID), email, and name.
    3. Create user if first-time login; re-use existing account if returning.
    4. Handle private-relay email edge cases safely.
    5. Return app JWT.

    iOS configuration notes:
    - Set APPLE_APP_BUNDLE_ID in backend .env to your app's Bundle ID
      (e.g. APPLE_APP_BUNDLE_ID=com.yourcompany.smartlifeplanner).
    - On Android: Apple Sign-In is NOT officially supported. The Flutter
      client must hide the button on Android (handled by platform check).
    - Apple ONLY sends full_name and email on the VERY FIRST sign-in.
      The Flutter client MUST pass them in the request body on that
      first call. On subsequent sign-ins they will be null.
    """
    if not app_settings.APPLE_APP_BUNDLE_ID:
        raise HTTPException(
            status_code=500,
            detail="Apple sign-in not configured. Set APPLE_APP_BUNDLE_ID in backend .env.",
        )

    # Fetch Apple public keys
    try:
        apple_keys = await _fetch_apple_public_keys()
    except Exception as exc:
        logger.warning("Failed to fetch Apple JWKS: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="Could not reach Apple servers to verify token. Please try again.",
        )

    claims = _verify_apple_identity_token(
        payload.identity_token,
        apple_keys,
        app_settings.APPLE_APP_BUNDLE_ID,
    )

    apple_user_id = claims.get("sub")  # Apple's stable, unique user identifier
    if not apple_user_id:
        raise HTTPException(status_code=400, detail="Apple token missing 'sub' claim")

    # Email: token claim takes priority; payload is fallback for first sign-in
    # Apple may return a private relay address like xyz@privaterelay.appleid.com
    email_from_token = claims.get("email")
    email = email_from_token or payload.email

    # Name: only available in payload on very first sign-in
    full_name = payload.full_name or (email.split("@")[0] if email else "Apple User")

    email_verified = claims.get("email_verified", False)
    # Apple may return "true" as a string
    if isinstance(email_verified, str):
        email_verified = email_verified.lower() == "true"

    # 1. Look up by Apple provider ID (stable across sessions)
    user = await get_user_by_provider(db, AuthProvider.apple, apple_user_id)

    if not user:
        if email:
            # Check if email already exists under a different provider
            existing = await get_user_by_email(db, email)
            if existing and existing.auth_provider != AuthProvider.apple:
                raise HTTPException(
                    status_code=409,
                    detail=(
                        "An account with this email already exists. "
                        "Please sign in with your original method."
                    ),
                )

        # Create new Apple user.
        # Note: email may be None when user chose "Hide My Email" and this is
        # a non-first-time call without a cached email. Use a placeholder.
        effective_email = email or f"apple_{apple_user_id}@privaterelay.appleid.com"
        user = await create_user(
            db,
            email=effective_email,
            full_name=full_name,
            hashed_password=None,  # Social login — no password
            auth_provider=AuthProvider.apple,
            provider_user_id=apple_user_id,
            is_verified=email_verified,
        )

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)


# ── Account Deletion ─────────────────────────────────────────────────────────
# Soft-delete with immediate email anonymisation.
# A background scheduled job (or manual DBA task) should hard-delete rows
# where deleted_at < NOW() - INTERVAL '30 days'.
#
# Soft-delete is preferred over immediate hard-delete because:
#   1. GDPR's "right to erasure" does not require instant data removal.
#   2. It allows a grace period for accidental deletions.
#   3. It avoids FK cascade issues on large related datasets.


@router.delete("/delete-account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    payload: DeleteAccountRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Permanently schedule the current user's account for deletion.

    Behaviour:
    - Email/password accounts: must supply a correct `password`.
    - Social (Google/Apple) accounts: must supply `confirmation = "DELETE"`.
    - The account is immediately deactivated (is_active=False) and the
      email is anonymised to prevent future sign-in or account recovery.
    - deleted_at is set to now. A separate job performs hard-deletion
      after 30 days (the data-retention window).
    - Returns HTTP 204 No Content. The client MUST clear its token.

    Security hardening:
    - Requires authenticated Bearer token (cannot be called without login).
    - Password accounts cannot use the `confirmation` bypass.
    - Social accounts cannot use a password they don't have.
    """
    is_social_user = current_user.hashed_password is None

    if is_social_user:
        # Social users confirm with the word "DELETE"
        if not payload.confirmation:
            raise HTTPException(
                status_code=400,
                detail="Social account deletion requires confirmation='DELETE'.",
            )
        # Already validated by pydantic that confirmation == 'DELETE'
    else:
        # Password users must supply their current password
        if not payload.password:
            raise HTTPException(
                status_code=400,
                detail="Password is required to delete your account.",
            )
        if not verify_password(payload.password, current_user.hashed_password):
            raise HTTPException(
                status_code=403,
                detail="Incorrect password. Account not deleted.",
            )

    # ─ Soft-delete: anonymise + deactivate ────────────────────────────────────
    now = datetime.now(timezone.utc)
    anonymised_email = f"deleted_{current_user.id}@removed.invalid"

    current_user.email = anonymised_email
    current_user.full_name = "Deleted User"
    current_user.hashed_password = None
    current_user.provider_user_id = None  # Revoke social link
    current_user.is_active = False
    current_user.is_verified = False
    current_user.deleted_at = now

    await db.commit()

    logger.info(
        "Account soft-deleted: original_id=%s anonymised_to=%s",
        current_user.id,
        anonymised_email,
    )

    # HTTP 204 — no body. Client must discard the JWT immediately.
    return None
