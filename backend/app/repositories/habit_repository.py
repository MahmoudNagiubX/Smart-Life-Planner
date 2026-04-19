import uuid
from datetime import datetime, date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.habit import Habit, HabitLog


async def get_habits(
    db: AsyncSession,
    user_id: uuid.UUID,
) -> list[Habit]:
    result = await db.execute(
        select(Habit)
        .where(Habit.user_id == user_id, Habit.is_deleted == False)
        .order_by(Habit.created_at.desc())
    )
    return list(result.scalars().all())


async def get_habit_by_id(
    db: AsyncSession, habit_id: uuid.UUID, user_id: uuid.UUID
) -> Habit | None:
    result = await db.execute(
        select(Habit).where(
            Habit.id == habit_id,
            Habit.user_id == user_id,
            Habit.is_deleted == False,
        )
    )
    return result.scalar_one_or_none()


async def create_habit(
    db: AsyncSession, user_id: uuid.UUID, data: dict
) -> Habit:
    habit = Habit(user_id=user_id, **data)
    db.add(habit)
    await db.commit()
    await db.refresh(habit)
    return habit


async def update_habit(
    db: AsyncSession, habit: Habit, data: dict
) -> Habit:
    for key, value in data.items():
        setattr(habit, key, value)
    await db.commit()
    await db.refresh(habit)
    return habit


async def soft_delete_habit(db: AsyncSession, habit: Habit) -> None:
    habit.is_deleted = True
    await db.commit()


async def get_habit_log(
    db: AsyncSession, habit_id: uuid.UUID, log_date: date
) -> HabitLog | None:
    result = await db.execute(
        select(HabitLog).where(
            HabitLog.habit_id == habit_id,
            HabitLog.log_date == log_date,
        )
    )
    return result.scalar_one_or_none()


async def get_habit_logs(
    db: AsyncSession, habit_id: uuid.UUID, user_id: uuid.UUID
) -> list[HabitLog]:
    result = await db.execute(
        select(HabitLog)
        .where(HabitLog.habit_id == habit_id, HabitLog.user_id == user_id)
        .order_by(HabitLog.log_date.desc())
        .limit(30)
    )
    return list(result.scalars().all())


async def log_habit_completion(
    db: AsyncSession, habit: Habit, user_id: uuid.UUID, log_date: date
) -> HabitLog:
    existing = await get_habit_log(db, habit.id, log_date)
    if existing:
        existing.is_completed = True
        existing.completed_at = datetime.utcnow()
        await db.commit()
        await db.refresh(existing)
        await _update_streak(db, habit, log_date)
        return existing

    log = HabitLog(
        habit_id=habit.id,
        user_id=user_id,
        log_date=log_date,
        is_completed=True,
        completed_at=datetime.utcnow(),
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    await _update_streak(db, habit, log_date)
    return log


async def _update_streak(
    db: AsyncSession, habit: Habit, log_date: date
) -> None:
    streak = 0
    check_date = log_date
    while True:
        log = await get_habit_log(db, habit.id, check_date)
        if log and log.is_completed:
            streak += 1
            check_date = check_date - timedelta(days=1)
        else:
            break

    habit.current_streak = streak
    if streak > habit.longest_streak:
        habit.longest_streak = streak
    await db.commit()