import uuid
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, field_validator


class HasaeDailyPlanRequest(BaseModel):
    date: Optional[date] = None


class HasaePlanBlock(BaseModel):
    id: Optional[uuid.UUID] = None
    task_id: Optional[uuid.UUID] = None
    block_type: str
    title: str
    start_time: datetime
    end_time: datetime
    is_locked: bool = False
    explanation: Optional[str] = None
    score: Optional[float] = None

    @field_validator("block_type")
    @classmethod
    def block_type_valid(cls, value: str) -> str:
        allowed = {"task", "prayer", "focus", "habit", "break", "blocked"}
        if value not in allowed:
            raise ValueError("Invalid block_type")
        return value


class HasaePlanTask(BaseModel):
    task_id: uuid.UUID
    title: str
    score: float
    reason: str
    duration_minutes: int


class HasaeSkippedTask(BaseModel):
    task_id: uuid.UUID
    title: str
    reason: str


class HasaeDailyPlanResponse(BaseModel):
    date: str
    blocks: list[HasaePlanBlock]
    selected_tasks: list[HasaePlanTask]
    skipped_tasks: list[HasaeSkippedTask]
    overload_warning: bool
    overload_message: Optional[str]
    total_task_minutes: int
    scheduled_task_minutes: int
    available_minutes: int
    explanation: str
    requires_confirmation: bool = True
    persisted: bool = False
