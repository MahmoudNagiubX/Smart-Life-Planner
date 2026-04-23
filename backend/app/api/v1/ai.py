from datetime import date, datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.ai import (
    ParseTaskRequest,
    ParseTaskResponse,
    NextActionResponse,
    DailyPlanRequest,
    DailyPlanResponse,
    DailyPlanItem,
)
from app.repositories.task_repository import get_tasks
from app.repositories.prayer_repository import get_prayer_logs_for_date
from app.services.ai_service import (
    parse_task_from_text,
    get_next_action,
    generate_daily_plan,
)
from app.core.config import settings

router = APIRouter(prefix="/ai", tags=["ai"])


def _check_ai_configured():
    if not settings.GROQ_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not configured",
        )


@router.post("/parse-task", response_model=ParseTaskResponse)
async def parse_task(
    payload: ParseTaskRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _check_ai_configured()
    try:
        today = date.today().isoformat()
        result = await parse_task_from_text(payload.input_text, today)
        return ParseTaskResponse(
            success=True,
            data=result,
            raw_input=payload.input_text,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI parsing failed: {str(e)}",
        )


@router.get("/next-action", response_model=NextActionResponse)
async def next_action(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _check_ai_configured()
    try:
        tasks = await get_tasks(db, current_user.id, status="pending")
        tasks_data = [
            {
                "id": str(t.id),
                "title": t.title,
                "priority": t.priority,
                "due_at": t.due_at.isoformat() if t.due_at else None,
                "estimated_minutes": t.estimated_minutes,
            }
            for t in tasks
        ]
        result = await get_next_action(tasks_data)
        return NextActionResponse(
            task_id=result.get("task_id"),
            title=result.get("title"),
            reason=result.get("reason", "No suggestion available"),
            confidence=result.get("confidence", "low"),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI next action failed: {str(e)}",
        )


@router.post("/daily-plan", response_model=DailyPlanResponse)
async def daily_plan(
    payload: DailyPlanRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _check_ai_configured()
    try:
        plan_date = date.fromisoformat(payload.date) if payload.date else date.today()

        tasks = await get_tasks(db, current_user.id, status="pending")
        tasks_data = [
            {
                "id": str(t.id),
                "title": t.title,
                "priority": t.priority,
                "due_at": t.due_at.isoformat() if t.due_at else None,
                "estimated_minutes": t.estimated_minutes or 30,
            }
            for t in tasks
        ]

        prayer_logs = await get_prayer_logs_for_date(db, current_user.id, plan_date)
        prayers_data = [
            {
                "prayer_name": p.prayer_name,
                "scheduled_at": p.scheduled_at.isoformat() if p.scheduled_at else None,
            }
            for p in prayer_logs
        ]

        result = await generate_daily_plan(tasks_data, prayers_data)

        plan_items = [
            DailyPlanItem(
                task_id=item.get("task_id", ""),
                title=item.get("title", ""),
                suggested_time=item.get("suggested_time", "09:00"),
                duration_minutes=item.get("duration_minutes", 30),
                reason=item.get("reason", ""),
            )
            for item in result
            if isinstance(item, dict)
        ]

        return DailyPlanResponse(
            date=plan_date.isoformat(),
            plan=plan_items,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI daily plan failed: {str(e)}",
        )