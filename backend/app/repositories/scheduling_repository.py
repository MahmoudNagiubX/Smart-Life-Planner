import uuid
from datetime import date, datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.task import Task, TaskDependency
from app.models.scheduling import DailySchedule, ScheduleBlock


# ── Dependencies ──────────────────────────────────────────

async def get_dependencies(
    db: AsyncSession, task_id: uuid.UUID, user_id: uuid.UUID
) -> list[TaskDependency]:
    result = await db.execute(
        select(TaskDependency)
        .where(
            TaskDependency.task_id == task_id,
            TaskDependency.user_id == user_id,
        )
    )
    return list(result.scalars().all())


async def get_dependency(
    db: AsyncSession,
    task_id: uuid.UUID,
    depends_on_task_id: uuid.UUID,
    user_id: uuid.UUID,
) -> TaskDependency | None:
    result = await db.execute(
        select(TaskDependency).where(
            TaskDependency.task_id == task_id,
            TaskDependency.depends_on_task_id == depends_on_task_id,
            TaskDependency.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def create_dependency(
    db: AsyncSession,
    task_id: uuid.UUID,
    depends_on_task_id: uuid.UUID,
    user_id: uuid.UUID,
    dependency_type: str = "finish_to_start",
) -> TaskDependency:
    dep = TaskDependency(
        task_id=task_id,
        depends_on_task_id=depends_on_task_id,
        user_id=user_id,
        dependency_type=dependency_type,
    )
    db.add(dep)
    await db.commit()
    await db.refresh(dep)
    return dep


async def delete_dependency(
    db: AsyncSession, dependency: TaskDependency
) -> None:
    await db.delete(dependency)
    await db.commit()


async def check_task_readiness(
    db: AsyncSession, task_id: uuid.UUID, user_id: uuid.UUID
) -> dict:
    deps = await get_dependencies(db, task_id, user_id)
    if not deps:
        return {
            "is_ready": True,
            "is_blocked": False,
            "blocking_tasks": [],
            "explanation": "No dependencies - task is ready to start.",
        }

    blocking = []
    for dep in deps:
        prereq_result = await db.execute(
            select(Task).where(Task.id == dep.depends_on_task_id)
        )
        prereq = prereq_result.scalar_one_or_none()
        if prereq and prereq.status != "completed":
            blocking.append({
                "task_id": str(prereq.id),
                "title": prereq.title,
                "status": prereq.status,
                "priority": prereq.priority,
            })

    if blocking:
        titles = ", ".join(b["title"] for b in blocking)
        return {
            "is_ready": False,
            "is_blocked": True,
            "blocking_tasks": blocking,
            "explanation": f"Blocked by: {titles}",
        }

    return {
        "is_ready": True,
        "is_blocked": False,
        "blocking_tasks": [],
        "explanation": "All prerequisites completed - task is ready.",
    }


# ── Schedule Blocks ────────────────────────────────────────

async def get_or_create_daily_schedule(
    db: AsyncSession, user_id: uuid.UUID, schedule_date: date
) -> DailySchedule:
    result = await db.execute(
        select(DailySchedule)
        .where(
            DailySchedule.user_id == user_id,
            DailySchedule.schedule_date == schedule_date,
        )
        .options(selectinload(DailySchedule.blocks))
    )
    schedule = result.scalar_one_or_none()
    if not schedule:
        schedule = DailySchedule(user_id=user_id, schedule_date=schedule_date)
        db.add(schedule)
        await db.commit()
        await db.refresh(schedule)
    return schedule


async def get_daily_schedule_with_blocks(
    db: AsyncSession, user_id: uuid.UUID, schedule_date: date
) -> DailySchedule | None:
    result = await db.execute(
        select(DailySchedule)
        .where(
            DailySchedule.user_id == user_id,
            DailySchedule.schedule_date == schedule_date,
        )
        .options(selectinload(DailySchedule.blocks))
    )
    return result.scalar_one_or_none()


async def create_schedule_block(
    db: AsyncSession,
    schedule_id: uuid.UUID,
    user_id: uuid.UUID,
    data: dict,
) -> ScheduleBlock:
    block = ScheduleBlock(schedule_id=schedule_id, user_id=user_id, **data)
    db.add(block)
    await db.commit()
    await db.refresh(block)
    return block


async def update_block_completion(
    db: AsyncSession, block: ScheduleBlock
) -> ScheduleBlock:
    block.is_completed = True
    await db.commit()
    await db.refresh(block)
    return block


async def delete_schedule_block(
    db: AsyncSession, block: ScheduleBlock
) -> None:
    await db.delete(block)
    await db.commit()


async def get_block_by_id(
    db: AsyncSession, block_id: uuid.UUID, user_id: uuid.UUID
) -> ScheduleBlock | None:
    result = await db.execute(
        select(ScheduleBlock).where(
            ScheduleBlock.id == block_id,
            ScheduleBlock.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()
