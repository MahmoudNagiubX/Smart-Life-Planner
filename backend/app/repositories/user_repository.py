import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User, UserSettings, AuthProvider


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_user_by_provider(
    db: AsyncSession, provider: AuthProvider, provider_user_id: str
) -> User | None:
    result = await db.execute(
        select(User).where(
            User.auth_provider == provider,
            User.provider_user_id == provider_user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_user(
    db: AsyncSession,
    email: str,
    full_name: str,
    hashed_password: str | None = None,
    auth_provider: AuthProvider = AuthProvider.email,
    provider_user_id: str | None = None,
    is_verified: bool = False,
) -> User:
    user = User(
        email=email,
        full_name=full_name,
        hashed_password=hashed_password,
        auth_provider=auth_provider,
        provider_user_id=provider_user_id,
        is_verified=is_verified,
    )
    db.add(user)
    await db.flush()

    settings = UserSettings(user_id=user.id)
    db.add(settings)
    await db.commit()
    await db.refresh(user)
    return user