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
from app.models.verification import EmailVerification
from app.repositories.user_repository import (
    get_user_by_email,
    create_user,
    get_user_by_id,
)
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserResponse,
    TokenResponse,
    VerifyEmailRequest,
    ResendVerificationRequest,
)
from app.services.email_service import send_verification_email
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

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


@router.get("/me", response_model=UserResponse)
async def get_me(current_user=Depends(get_current_user)):
    return current_user