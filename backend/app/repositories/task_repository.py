import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.task import Task, TaskCompletionEvent, TaskProject, TaskSubtask
from app.repositories.reminder_repository import (
    invalidate_task_reminders,
    resync_task_due_preset_reminders,
)
from app.services.reminder_lifecycle import (
    log_task_reminders_cancelled,
    log_task_reminders_rescheduled,
)


# ── Projects ──────────────────────────────────────────────

async def get_projects(db: AsyncSession, user_id: uuid.UUID) -> list[TaskProject]:
    result = await db.execute(
        select(TaskProject)
        .where(TaskProject.user_id == user_id, TaskProject.status != "deleted")
        .order_by(TaskProject.created_at.desc())
    )
    return list(result.scalars().all())


async def get_project_by_id(db: AsyncSession, project_id: uuid.UUID, user_id: uuid.UUID) -> TaskProject | None:
    result = await db.execute(
        select(TaskProject).where(TaskProject.id == project_id, TaskProject.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_project(db: AsyncSession, user_id: uuid.UUID, data: dict) -> TaskProject:
    project = TaskProject(user_id=user_id, **data)
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return project


async def update_project(db: AsyncSession, project: TaskProject, data: dict) -> TaskProject:
    for key, value in data.items():
        if value is not None:
            setattr(project, key, value)
    await db.commit()
    await db.refresh(project)
    return project


# ── Tasks ──────────────────────────────────────────────────

async def get_tasks(
    db: AsyncSession,
    user_id: uuid.UUID,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    project_id: Optional[uuid.UUID] = None,
) -> list[Task]:
    query = (
        select(Task)
        .where(Task.user_id == user_id, Task.is_deleted == False)
        .options(selectinload(Task.subtasks))
        .order_by(Task.manual_order.asc(), Task.created_at.desc())
    )
    if status:
        query = query.where(Task.status == status)
    if priority:
        query = query.where(Task.priority == priority)
    if project_id:
        query = query.where(Task.project_id == project_id)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_tasks_in_date_range(
    db: AsyncSession,
    user_id: uuid.UUID,
    start_at: datetime,
    end_at: datetime,
) -> list[Task]:
    result = await db.execute(
        select(Task)
        .where(
            Task.user_id == user_id,
            Task.is_deleted == False,
            Task.due_at.is_not(None),
            Task.due_at >= start_at,
            Task.due_at < end_at,
        )
        .options(selectinload(Task.subtasks))
        .order_by(Task.due_at.asc(), Task.manual_order.asc())
    )
    return list(result.scalars().all())


async def get_project_timeline_tasks(
    db: AsyncSession,
    user_id: uuid.UUID,
    project_id: uuid.UUID,
) -> list[Task]:
    result = await db.execute(
        select(Task)
        .where(
            Task.user_id == user_id,
            Task.project_id == project_id,
            Task.is_deleted == False,
        )
        .options(selectinload(Task.dependencies))
        .order_by(Task.manual_order.asc(), Task.due_at.asc(), Task.created_at.asc())
    )
    return list(result.scalars().all())


async def get_task_by_id(db: AsyncSession, task_id: uuid.UUID, user_id: uuid.UUID) -> Task | None:
    result = await db.execute(
        select(Task)
        .where(Task.id == task_id, Task.user_id == user_id, Task.is_deleted == False)
        .options(selectinload(Task.subtasks))
    )
    return result.scalar_one_or_none()


async def create_task(db: AsyncSession, user_id: uuid.UUID, data: dict) -> Task:
    task = Task(user_id=user_id, **data)
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return await get_task_by_id(db, task.id, user_id)


async def update_task(db: AsyncSession, task: Task, data: dict) -> Task:
    previous_due_at = task.due_at
    previous_reminder_at = task.reminder_at
    previous_status = task.status
    for key, value in data.items():
        setattr(task, key, value)

    now = datetime.now(timezone.utc)
    if previous_status != "completed" and task.status == "completed":
        task.completed_at = task.completed_at or now
        db.add(
            _task_completion_event(
                task,
                "completed",
                previous_status,
                "completed",
                task.completed_at,
            )
        )
    elif previous_status == "completed" and task.status != "completed":
        task.completed_at = None
        db.add(
            _task_completion_event(
                task,
                "reopened",
                previous_status,
                task.status,
                now,
            )
        )

    reminder_fields_changed = (
        ("due_at" in data and data["due_at"] != previous_due_at)
        or ("reminder_at" in data and data["reminder_at"] != previous_reminder_at)
    )
    await db.commit()
    await db.refresh(task)
    if previous_status != "completed" and task.status == "completed":
        await invalidate_task_reminders(
            db,
            user_id=task.user_id,
            task_id=task.id,
            reason="task_completed",
        )
    if reminder_fields_changed:
        await resync_task_due_preset_reminders(db, task)
        log_task_reminders_rescheduled(
            user_id=task.user_id,
            task_id=task.id,
            previous_due_at=previous_due_at,
            previous_reminder_at=previous_reminder_at,
            next_due_at=task.due_at,
            next_reminder_at=task.reminder_at,
        )
    return await get_task_by_id(db, task.id, task.user_id)


async def reorder_tasks(
    db: AsyncSession,
    user_id: uuid.UUID,
    task_ids: list[uuid.UUID],
) -> list[Task] | None:
    result = await db.execute(
        select(Task).where(
            Task.user_id == user_id,
            Task.is_deleted == False,
            Task.id.in_(task_ids),
        )
    )
    tasks = list(result.scalars().all())
    if len(tasks) != len(task_ids):
        return None

    by_id = {task.id: task for task in tasks}
    for index, task_id in enumerate(task_ids):
        by_id[task_id].manual_order = index

    await db.commit()

    refreshed = await db.execute(
        select(Task)
        .where(Task.user_id == user_id, Task.id.in_(task_ids))
        .options(selectinload(Task.subtasks))
        .order_by(Task.manual_order.asc())
    )
    return list(refreshed.scalars().all())


async def complete_task(db: AsyncSession, task: Task) -> Task:
    previous_status = task.status
    completed_at = datetime.now(timezone.utc)
    task.status = "completed"
    task.completed_at = completed_at
    cancelled_reminder = task.reminder_at is not None
    if cancelled_reminder:
        task.reminder_at = None
    db.add(
        _task_completion_event(
            task,
            "completed",
            previous_status,
            "completed",
            completed_at,
        )
    )
    await db.commit()
    await db.refresh(task)
    await invalidate_task_reminders(
        db,
        user_id=task.user_id,
        task_id=task.id,
        reason="task_completed",
    )
    if cancelled_reminder:
        log_task_reminders_cancelled(
            user_id=task.user_id,
            task_id=task.id,
            reason="completed",
        )
    return task


async def reopen_task(db: AsyncSession, task: Task) -> Task:
    previous_status = task.status
    task.status = "pending"
    task.completed_at = None
    db.add(
        _task_completion_event(
            task,
            "reopened",
            previous_status,
            "pending",
            datetime.now(timezone.utc),
        )
    )
    await db.commit()
    await db.refresh(task)
    return task


async def get_task_completion_events(
    db: AsyncSession,
    task_id: uuid.UUID,
    user_id: uuid.UUID,
) -> list[TaskCompletionEvent] | None:
    task = await get_task_by_id(db, task_id, user_id)
    if not task:
        return None
    result = await db.execute(
        select(TaskCompletionEvent)
        .where(
            TaskCompletionEvent.user_id == user_id,
            TaskCompletionEvent.task_id == task_id,
        )
        .order_by(TaskCompletionEvent.occurred_at.desc())
    )
    return list(result.scalars().all())


def _task_completion_event(
    task: Task,
    event_type: str,
    previous_status: str | None,
    next_status: str,
    occurred_at: datetime,
) -> TaskCompletionEvent:
    return TaskCompletionEvent(
        user_id=task.user_id,
        task_id=task.id,
        event_type=event_type,
        previous_status=previous_status,
        next_status=next_status,
        occurred_at=occurred_at,
    )


async def soft_delete_task(db: AsyncSession, task: Task) -> None:
    task.is_deleted = True
    cancelled_reminder = task.reminder_at is not None
    if cancelled_reminder:
        task.reminder_at = None
    await db.commit()
    await invalidate_task_reminders(
        db,
        user_id=task.user_id,
        task_id=task.id,
        reason="task_deleted",
    )
    if cancelled_reminder:
        log_task_reminders_cancelled(
            user_id=task.user_id,
            task_id=task.id,
            reason="deleted",
        )


# ── Subtasks ───────────────────────────────────────────────

async def create_subtask(db: AsyncSession, task_id: uuid.UUID, data: dict) -> TaskSubtask:
    subtask = TaskSubtask(task_id=task_id, **data)
    db.add(subtask)
    await db.commit()
    await db.refresh(subtask)
    return subtask


async def complete_subtask(db: AsyncSession, subtask: TaskSubtask) -> TaskSubtask:
    subtask.is_completed = True
    subtask.completed_at = datetime.utcnow()
    await db.commit()
    await db.refresh(subtask)
    return subtask


async def delete_subtask(db: AsyncSession, subtask: TaskSubtask) -> None:
    await db.delete(subtask)
    await db.commit()


async def get_subtask_by_id(db: AsyncSession, subtask_id: uuid.UUID, task_id: uuid.UUID) -> TaskSubtask | None:
    result = await db.execute(
        select(TaskSubtask).where(TaskSubtask.id == subtask_id, TaskSubtask.task_id == task_id)
    )
    return result.scalar_one_or_none()

async def bulk_create_tasks(
    db: AsyncSession,
    user_id: uuid.UUID,
    tasks_data: list[dict],
) -> list[Task]:
    created = []
    for task_data in tasks_data:
        subtasks_data = task_data.pop("subtasks", [])
        task = Task(user_id=user_id, **task_data)
        db.add(task)
        await db.flush()

        for sub in subtasks_data:
            subtask = TaskSubtask(
                task_id=task.id,
                title=sub.get("title", ""),
                is_completed=sub.get("completed", False),
            )
            db.add(subtask)

        created.append(task)

    await db.commit()

    # Reload all with subtasks
    result = []
    for t in created:
        refreshed = await get_task_by_id(db, t.id, user_id)
        if refreshed:
            result.append(refreshed)
    return result
