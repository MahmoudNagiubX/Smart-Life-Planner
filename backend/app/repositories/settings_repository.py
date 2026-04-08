from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import UserSettings
import uuid

async def get_settings_by_user_id(db: AsyncSession, user_id: uuid.UUID) -> UserSettings | None:
    result = await db.execute(select(UserSettings).where(UserSettings.user_id == user_id))
    return result.scalar_one_or_none()

async def update_settings(db: AsyncSession, user_id: uuid.UUID, data: dict) -> UserSettings | None:
    settings = await get_settings_by_user_id(db, user_id)
    if not settings:
        return None
    for key, value in data.items():
        if value is not None:
            setattr(settings, key, value)
    await db.commit()
    await db.refresh(settings)
    return settings