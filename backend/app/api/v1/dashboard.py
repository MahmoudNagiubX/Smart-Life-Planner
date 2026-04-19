import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.models.task import Task

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/home")
async def get_home_dashboard(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id: uuid.UUID = current_user.id
    today = datetime.now(timezone.utc).date()

    # Total pending tasks
    pending_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.is_deleted == False,
        )
    )
    pending_count = pending_result.scalar() or 0

    # Completed today
    completed_result = await db.execute(
        select(func.count(Task.id)).where(
            Task.user_id == user_id,
            Task.status == "completed",
            Task.is_deleted == False,
            func.date(Task.completed_at) == today,
        )
    )
    completed_today = completed_result.scalar() or 0

    # Top 5 pending tasks ordered by priority then created_at
    priority_order = {"high": 1, "medium": 2, "low": 3}
    top_tasks_result = await db.execute(
        select(Task)
        .where(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.is_deleted == False,
        )
        .order_by(Task.due_at.asc().nulls_last(), Task.created_at.asc())
        .limit(5)
    )
    top_tasks = top_tasks_result.scalars().all()

    return {
        "pending_count": pending_count,
        "completed_today": completed_today,
        "top_tasks": [
            {
                "id": str(t.id),
                "title": t.title,
                "priority": t.priority,
                "due_at": t.due_at.isoformat() if t.due_at else None,
                "status": t.status,
            }
            for t in top_tasks
        ],
    }
