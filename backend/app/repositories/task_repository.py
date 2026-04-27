import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.task import Task, TaskProject, TaskSubtask
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
        .order_by(Task.created_at.desc())
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
        .order_by(Task.due_at.asc())
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
    for key, value in data.items():
        setattr(task, key, value)
    reminder_fields_changed = (
        ("due_at" in data and data["due_at"] != previous_due_at)
        or ("reminder_at" in data and data["reminder_at"] != previous_reminder_at)
    )
    await db.commit()
    await db.refresh(task)
    if reminder_fields_changed:
        log_task_reminders_rescheduled(
            user_id=task.user_id,
            task_id=task.id,
            previous_due_at=previous_due_at,
            previous_reminder_at=previous_reminder_at,
            next_due_at=task.due_at,
            next_reminder_at=task.reminder_at,
        )
    return await get_task_by_id(db, task.id, task.user_id)


async def complete_task(db: AsyncSession, task: Task) -> Task:
    task.status = "completed"
    task.completed_at = datetime.utcnow()
    cancelled_reminder = task.reminder_at is not None
    if cancelled_reminder:
        task.reminder_at = None
    await db.commit()
    await db.refresh(task)
    if cancelled_reminder:
        log_task_reminders_cancelled(
            user_id=task.user_id,
            task_id=task.id,
            reason="completed",
        )
    return task


async def reopen_task(db: AsyncSession, task: Task) -> Task:
    task.status = "pending"
    task.completed_at = None
    await db.commit()
    await db.refresh(task)
    return task


async def soft_delete_task(db: AsyncSession, task: Task) -> None:
    task.is_deleted = True
    cancelled_reminder = task.reminder_at is not None
    if cancelled_reminder:
        task.reminder_at = None
    await db.commit()
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
