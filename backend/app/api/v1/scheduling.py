import uuid
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.scheduling import (
    TaskDependencyCreate,
    TaskDependencyResponse,
    TaskReadinessResponse,
    ScheduleBlockCreate,
    ScheduleBlockResponse,
    DailyScheduleResponse,
)
from app.repositories.scheduling_repository import (
    get_dependencies,
    get_dependency,
    create_dependency,
    delete_dependency,
    check_task_readiness,
    get_or_create_daily_schedule,
    get_daily_schedule_with_blocks,
    create_schedule_block,
    update_block_completion,
    delete_schedule_block,
    get_block_by_id,
)
from app.repositories.task_repository import get_task_by_id

router = APIRouter(prefix="/scheduling", tags=["scheduling"])


# ── Task Dependencies ──────────────────────────────────────

@router.get("/tasks/{task_id}/dependencies",
            response_model=list[TaskDependencyResponse])
async def list_dependencies(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    deps = await get_dependencies(db, task_id, current_user.id)
    result = []
    for dep in deps:
        prereq = await get_task_by_id(db, dep.depends_on_task_id, current_user.id)
        result.append(TaskDependencyResponse(
            id=dep.id,
            task_id=dep.task_id,
            depends_on_task_id=dep.depends_on_task_id,
            dependency_type=dep.dependency_type,
            created_at=dep.created_at,
            prerequisite_title=prereq.title if prereq else None,
            prerequisite_status=prereq.status if prereq else None,
        ))
    return result


@router.post("/tasks/{task_id}/dependencies",
             response_model=TaskDependencyResponse,
             status_code=status.HTTP_201_CREATED)
async def add_dependency(
    task_id: uuid.UUID,
    payload: TaskDependencyCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if task_id == payload.depends_on_task_id:
        raise HTTPException(
            status_code=400,
            detail="A task cannot depend on itself",
        )

    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    prereq = await get_task_by_id(db, payload.depends_on_task_id, current_user.id)
    if not prereq:
        raise HTTPException(status_code=404, detail="Prerequisite task not found")

    existing = await get_dependency(
        db, task_id, payload.depends_on_task_id, current_user.id
    )
    if existing:
        raise HTTPException(
            status_code=409, detail="Dependency already exists"
        )

    dep = await create_dependency(
        db,
        task_id,
        payload.depends_on_task_id,
        current_user.id,
        payload.dependency_type,
    )
    return TaskDependencyResponse(
        id=dep.id,
        task_id=dep.task_id,
        depends_on_task_id=dep.depends_on_task_id,
        dependency_type=dep.dependency_type,
        created_at=dep.created_at,
        prerequisite_title=prereq.title,
        prerequisite_status=prereq.status,
    )


@router.delete("/tasks/{task_id}/dependencies/{depends_on_task_id}",
               status_code=status.HTTP_204_NO_CONTENT)
async def remove_dependency(
    task_id: uuid.UUID,
    depends_on_task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    dep = await get_dependency(db, task_id, depends_on_task_id, current_user.id)
    if not dep:
        raise HTTPException(status_code=404, detail="Dependency not found")
    await delete_dependency(db, dep)


@router.get("/tasks/{task_id}/readiness",
            response_model=TaskReadinessResponse)
async def task_readiness(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    readiness = await check_task_readiness(db, task_id, current_user.id)
    return TaskReadinessResponse(
        task_id=task_id,
        title=task.title,
        **readiness,
    )


# ── Schedule Blocks ────────────────────────────────────────

@router.get("/schedule", response_model=DailyScheduleResponse)
async def get_schedule(
    schedule_date: date = Query(default=None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = schedule_date or date.today()
    schedule = await get_daily_schedule_with_blocks(
        db, current_user.id, target_date
    )

    if not schedule:
        return DailyScheduleResponse(
            date=target_date.isoformat(),
            blocks=[],
            overload_detected=False,
            overload_message=None,
            total_scheduled_minutes=0,
            available_minutes=480,
        )

    blocks = sorted(schedule.blocks, key=lambda b: b.start_time)
    total_minutes = sum(
        int((b.end_time - b.start_time).total_seconds() / 60)
        for b in blocks
    )
    available = max(0, 480 - total_minutes)

    return DailyScheduleResponse(
        date=target_date.isoformat(),
        blocks=[ScheduleBlockResponse(
            id=b.id,
            user_id=b.user_id,
            task_id=b.task_id,
            block_type=b.block_type,
            title=b.title,
            start_time=b.start_time,
            end_time=b.end_time,
            is_locked=b.is_locked,
            is_completed=b.is_completed,
            schedule_date=b.schedule_date,
            explanation=b.explanation,
            created_at=b.created_at,
        ) for b in blocks],
        overload_detected=schedule.is_overloaded,
        overload_message=schedule.overload_message,
        total_scheduled_minutes=total_minutes,
        available_minutes=available,
    )


@router.post("/schedule/blocks",
             response_model=ScheduleBlockResponse,
             status_code=status.HTTP_201_CREATED)
async def add_block(
    payload: ScheduleBlockCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = payload.start_time.date()
    schedule = await get_or_create_daily_schedule(
        db, current_user.id, target_date
    )

    if payload.task_id:
        task = await get_task_by_id(db, payload.task_id, current_user.id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")

    block = await create_schedule_block(
        db,
        schedule.id,
        current_user.id,
        payload.model_dump(),
    )

    return ScheduleBlockResponse(
        id=block.id,
        user_id=block.user_id,
        task_id=block.task_id,
        block_type=block.block_type,
        title=block.title,
        start_time=block.start_time,
        end_time=block.end_time,
        is_locked=block.is_locked,
        is_completed=block.is_completed,
        schedule_date=block.schedule_date,
        explanation=block.explanation,
        created_at=block.created_at,
    )


@router.patch("/schedule/blocks/{block_id}/complete",
              response_model=ScheduleBlockResponse)
async def complete_block(
    block_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    block = await get_block_by_id(db, block_id, current_user.id)
    if not block:
        raise HTTPException(status_code=404, detail="Block not found")
    block = await update_block_completion(db, block)
    return ScheduleBlockResponse(
        id=block.id,
        user_id=block.user_id,
        task_id=block.task_id,
        block_type=block.block_type,
        title=block.title,
        start_time=block.start_time,
        end_time=block.end_time,
        is_locked=block.is_locked,
        is_completed=block.is_completed,
        schedule_date=block.schedule_date,
        explanation=block.explanation,
        created_at=block.created_at,
    )


@router.delete("/schedule/blocks/{block_id}",
               status_code=status.HTTP_204_NO_CONTENT)
async def remove_block(
    block_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    block = await get_block_by_id(db, block_id, current_user.id)
    if not block:
        raise HTTPException(status_code=404, detail="Block not found")
    if block.is_locked:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete a locked block (e.g. prayer time)",
        )
    await delete_schedule_block(db, block)