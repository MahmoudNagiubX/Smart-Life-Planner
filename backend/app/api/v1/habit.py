import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.habit import HabitCreate, HabitUpdate, HabitResponse, HabitLogResponse
from app.repositories.habit_repository import (
    get_habits, get_habit_by_id, create_habit,
    update_habit, soft_delete_habit,
    log_habit_completion, get_habit_logs,
)

router = APIRouter(prefix="/habits", tags=["habits"])


@router.get("", response_model=list[HabitResponse])
async def list_habits(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_habits(db, current_user.id)


@router.post("", response_model=HabitResponse, status_code=status.HTTP_201_CREATED)
async def create_new_habit(
    payload: HabitCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await create_habit(db, current_user.id, payload.model_dump())


@router.get("/{habit_id}", response_model=HabitResponse)
async def get_habit(
    habit_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = await get_habit_by_id(db, habit_id, current_user.id)
    if not habit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")
    return habit


@router.patch("/{habit_id}", response_model=HabitResponse)
async def update_existing_habit(
    habit_id: uuid.UUID,
    payload: HabitUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = await get_habit_by_id(db, habit_id, current_user.id)
    if not habit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")
    return await update_habit(db, habit, payload.model_dump(exclude_none=True))


@router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_habit(
    habit_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = await get_habit_by_id(db, habit_id, current_user.id)
    if not habit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")
    await soft_delete_habit(db, habit)


@router.post("/{habit_id}/complete", response_model=HabitLogResponse)
async def complete_habit(
    habit_id: uuid.UUID,
    log_date: date = Query(default=None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = await get_habit_by_id(db, habit_id, current_user.id)
    if not habit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")
    today = log_date or date.today()
    return await log_habit_completion(db, habit, current_user.id, today)


@router.get("/{habit_id}/logs", response_model=list[HabitLogResponse])
async def get_logs(
    habit_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    habit = await get_habit_by_id(db, habit_id, current_user.id)
    if not habit:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Habit not found")
    return await get_habit_logs(db, habit_id, current_user.id)