import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.feedback import FeedbackMessage


async def create_feedback(
    db: AsyncSession,
    user_id: uuid.UUID,
    data: dict,
) -> FeedbackMessage:
    feedback = FeedbackMessage(user_id=user_id, **data)
    db.add(feedback)
    await db.commit()
    await db.refresh(feedback)
    return feedback
