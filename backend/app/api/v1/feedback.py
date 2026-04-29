from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.auth import get_current_user
from app.core.dependencies import get_db
from app.repositories.feedback_repository import create_feedback
from app.schemas.feedback import FeedbackCreate, FeedbackResponse

router = APIRouter(prefix="/support", tags=["support"])


@router.post(
    "/feedback",
    response_model=FeedbackResponse,
    status_code=status.HTTP_201_CREATED,
)
async def submit_feedback(
    payload: FeedbackCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    feedback = await create_feedback(
        db,
        current_user.id,
        payload.model_dump(exclude_none=True),
    )
    return {
        "id": feedback.id,
        "category": feedback.category,
        "status": feedback.status,
        "created_at": feedback.created_at,
        "message": "Feedback received",
    }
