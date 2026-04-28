import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.reminder import Reminder


async def get_reminders(
    db: AsyncSession,
    user_id: uuid.UUID,
    target_type: Optional[str] = None,
    target_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
) -> list[Reminder]:
    query = (
        select(Reminder)
        .where(Reminder.user_id == user_id)
        .order_by(Reminder.scheduled_at.asc(), Reminder.created_at.desc())
    )
    if target_type:
        query = query.where(Reminder.target_type == target_type)
    if target_id:
        query = query.where(Reminder.target_id == target_id)
    if status:
        query = query.where(Reminder.status == status)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_reminder_by_id(
    db: AsyncSession,
    reminder_id: uuid.UUID,
    user_id: uuid.UUID,
) -> Reminder | None:
    result = await db.execute(
        select(Reminder).where(
            Reminder.id == reminder_id,
            Reminder.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_reminder(
    db: AsyncSession,
    user_id: uuid.UUID,
    data: dict,
) -> Reminder:
    reminder = Reminder(user_id=user_id, **data)
    db.add(reminder)
    await db.commit()
    await db.refresh(reminder)
    return reminder


async def update_reminder(
    db: AsyncSession,
    reminder: Reminder,
    data: dict,
) -> Reminder:
    for key, value in data.items():
        setattr(reminder, key, value)
    await db.commit()
    await db.refresh(reminder)
    return reminder
