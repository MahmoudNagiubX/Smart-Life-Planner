import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


class TaskDependencyCreate(BaseModel):
    depends_on_task_id: uuid.UUID
    dependency_type: str = "finish_to_start"

    @field_validator("dependency_type")
    @classmethod
    def type_valid(cls, v: str) -> str:
        if v not in ("finish_to_start", "start_to_start", "finish_to_finish"):
            raise ValueError("Invalid dependency_type")
        return v


class TaskDependencyResponse(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    depends_on_task_id: uuid.UUID
    dependency_type: str
    created_at: datetime
    prerequisite_title: Optional[str] = None
    prerequisite_status: Optional[str] = None

    model_config = {"from_attributes": True}


class TaskReadinessResponse(BaseModel):
    task_id: uuid.UUID
    title: str
    is_ready: bool
    is_blocked: bool
    blocking_tasks: List[dict] = []
    explanation: str


class ScheduleBlockCreate(BaseModel):
    task_id: Optional[uuid.UUID] = None
    block_type: str = "task"
    title: str
    start_time: datetime
    end_time: datetime
    is_locked: bool = False

    @field_validator("block_type")
    @classmethod
    def block_type_valid(cls, v: str) -> str:
        if v not in ("task", "prayer", "focus", "habit", "break", "blocked"):
            raise ValueError("Invalid block_type")
        return v

    @field_validator("end_time")
    @classmethod
    def end_after_start(cls, v: datetime, info) -> datetime:
        if "start_time" in info.data and v <= info.data["start_time"]:
            raise ValueError("end_time must be after start_time")
        return v


class ScheduleBlockResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    task_id: Optional[uuid.UUID]
    block_type: str
    title: str
    start_time: datetime
    end_time: datetime
    is_locked: bool
    is_completed: bool
    schedule_date: str
    explanation: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class DailyScheduleResponse(BaseModel):
    date: str
    blocks: List[ScheduleBlockResponse]
    overload_detected: bool
    overload_message: Optional[str]
    total_scheduled_minutes: int
    available_minutes: int