import uuid
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.schemas.voice import BulkTaskCreateRequest, BulkTaskCreateResponse
from app.repositories.task_repository import bulk_create_tasks
from app.api.v1.auth import get_current_user
from app.schemas.task import (
    ProjectCreate,
    ProjectResponse,
    ProjectTimelineResponse,
    ProjectUpdate,
    SubtaskCreate,
    SubtaskResponse,
    TaskCompletionEventResponse,
    TaskCreate,
    TaskReorderRequest,
    TaskResponse,
    TaskUpdate,
)
from app.repositories.task_repository import (
    complete_subtask,
    complete_task,
    create_project,
    create_subtask,
    create_task,
    delete_subtask,
    get_project_by_id,
    get_project_timeline_tasks,
    get_projects,
    get_subtask_by_id,
    get_task_completion_events,
    get_task_by_id,
    get_tasks,
    get_tasks_in_date_range,
    reopen_task,
    reorder_tasks,
    soft_delete_task,
    update_project,
    update_task,
)
from app.services.project_timeline_service import build_project_timeline

router = APIRouter(prefix="/tasks", tags=["tasks"])
project_router = APIRouter(prefix="/projects", tags=["projects"])


# ── Projects ──────────────────────────────────────────────

@router.get("/projects", response_model=list[ProjectResponse])
async def list_projects(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_projects(db, current_user.id)


@router.post("/projects", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_new_project(
    payload: ProjectCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await create_project(db, current_user.id, payload.model_dump())


@router.patch("/projects/{project_id}", response_model=ProjectResponse)
async def update_existing_project(
    project_id: uuid.UUID,
    payload: ProjectUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    project = await get_project_by_id(db, project_id, current_user.id)
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return await update_project(db, project, payload.model_dump(exclude_none=True))


@project_router.get("/{project_id}/timeline", response_model=ProjectTimelineResponse)
async def get_project_timeline(
    project_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    project = await get_project_by_id(db, project_id, current_user.id)
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    tasks = await get_project_timeline_tasks(db, current_user.id, project_id)
    return build_project_timeline(project, tasks)


# ── Tasks ──────────────────────────────────────────────────

@router.get("", response_model=list[TaskResponse])
async def list_tasks(
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    project_id: Optional[uuid.UUID] = Query(None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_tasks(db, current_user.id, status, priority, project_id)


@router.get("/range", response_model=list[TaskResponse])
async def list_tasks_in_range(
    date_from: date = Query(...),
    date_to: date = Query(...),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if date_to < date_from:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="date_to must be on or after date_from",
        )
    if (date_to - date_from).days > 62:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Date range cannot exceed 62 days",
        )
    start_at = datetime.combine(date_from, time.min, tzinfo=timezone.utc)
    end_at = datetime.combine(
        date_to + timedelta(days=1),
        time.min,
        tzinfo=timezone.utc,
    )
    return await get_tasks_in_date_range(db, current_user.id, start_at, end_at)


@router.patch("/reorder", response_model=list[TaskResponse])
async def reorder_existing_tasks(
    payload: TaskReorderRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reordered = await reorder_tasks(db, current_user.id, payload.task_ids)
    if reordered is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="One or more tasks were not found",
        )
    return reordered


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_new_task(
    payload: TaskCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if payload.project_id:
        project = await get_project_by_id(db, payload.project_id, current_user.id)
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return await create_task(db, current_user.id, _task_payload_data(payload))


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.get(
    "/{task_id}/completion-history",
    response_model=list[TaskCompletionEventResponse],
)
async def get_task_completion_history(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    events = await get_task_completion_events(db, task_id, current_user.id)
    if events is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found",
        )
    return events


@router.patch("/{task_id}", response_model=TaskResponse)
async def update_existing_task(
    task_id: uuid.UUID,
    payload: TaskUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return await update_task(db, task, _task_payload_data(payload, exclude_unset=True))


@router.patch("/{task_id}/complete", response_model=TaskResponse)
async def mark_task_complete(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    if task.status == "completed":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Task already completed")
    return await complete_task(db, task)


@router.patch("/{task_id}/reopen", response_model=TaskResponse)
async def reopen_existing_task(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    if task.status != "completed":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Task is not completed")
    return await reopen_task(db, task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    await soft_delete_task(db, task)


# ── Subtasks ───────────────────────────────────────────────

@router.post("/{task_id}/subtasks", response_model=SubtaskResponse, status_code=status.HTTP_201_CREATED)
async def add_subtask(
    task_id: uuid.UUID,
    payload: SubtaskCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return await create_subtask(db, task_id, payload.model_dump())


@router.patch("/{task_id}/subtasks/{subtask_id}/complete", response_model=SubtaskResponse)
async def mark_subtask_complete(
    task_id: uuid.UUID,
    subtask_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    subtask = await get_subtask_by_id(db, subtask_id, task_id)
    if not subtask:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subtask not found")
    return await complete_subtask(db, subtask)


@router.delete("/{task_id}/subtasks/{subtask_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_subtask(
    task_id: uuid.UUID,
    subtask_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    task = await get_task_by_id(db, task_id, current_user.id)
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    subtask = await get_subtask_by_id(db, subtask_id, task_id)
    if not subtask:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subtask not found")
    await delete_subtask(db, subtask)
    
@router.post("/bulk-create", response_model=BulkTaskCreateResponse)
async def bulk_create(
    payload: BulkTaskCreateRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tasks_data = []
    for item in payload.tasks:
        data = item.model_dump()
        subtasks = data.pop("subtasks", [])

        # Convert due_date string to datetime if provided
        due_at = None
        if data.get("due_at"):
            try:
                from datetime import datetime
                raw = data["due_at"]
                if "T" in raw:
                    due_at = datetime.fromisoformat(raw)
                else:
                    due_at = datetime.fromisoformat(f"{raw}T00:00:00")
            except Exception:
                due_at = None

        tasks_data.append({
            "title": data["title"],
            "description": data.get("description"),
            "priority": data.get("priority", "medium"),
            "due_at": due_at,
            "estimated_minutes": data.get("estimated_duration_minutes"),
            "category": data.get("category"),
            "subtasks": subtasks,
        })

    created = await bulk_create_tasks(db, current_user.id, tasks_data)

    return BulkTaskCreateResponse(
        created_count=len(created),
        tasks=[
            {
                "id": str(t.id),
                "title": t.title,
                "priority": t.priority,
                "status": t.status,
            }
            for t in created
        ],
    )


def _task_payload_data(payload: TaskCreate | TaskUpdate, *, exclude_unset: bool = False) -> dict:
    data = payload.model_dump(exclude_unset=exclude_unset)
    if "start_date" in data:
        data["earliest_start_at"] = data.pop("start_date")
    if "estimated_duration_minutes" in data:
        estimated_duration = data.pop("estimated_duration_minutes")
        if data.get("estimated_minutes") is None:
            data["estimated_minutes"] = estimated_duration
    return data
