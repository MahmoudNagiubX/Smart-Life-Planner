import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


class ProjectCreate(BaseModel):
    title: str
    description: Optional[str] = None
    color_code: Optional[str] = None

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Title cannot be empty")
        return v.strip()


class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    color_code: Optional[str] = None
    status: Optional[str] = None


class ProjectResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: Optional[str]
    color_code: Optional[str]
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class SubtaskCreate(BaseModel):
    title: str
    sort_order: int = 0


class SubtaskResponse(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    title: str
    is_completed: bool
    completed_at: Optional[datetime]
    sort_order: int
    created_at: datetime

    model_config = {"from_attributes": True}


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    priority: Optional[str] = "medium"
    due_at: Optional[datetime] = None
    reminder_at: Optional[datetime] = None
    project_id: Optional[uuid.UUID] = None
    category: Optional[str] = None
    estimated_minutes: Optional[int] = None
    manual_order: int = 0

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Title cannot be empty")
        return v.strip()

    @field_validator("priority")
    @classmethod
    def priority_valid(cls, v: str) -> str:
        if v not in ("low", "medium", "high"):
            raise ValueError("Priority must be low, medium, or high")
        return v

    @field_validator("manual_order")
    @classmethod
    def manual_order_valid(cls, v: int | None) -> int:
        if v is None:
            return 0
        if v < 0:
            raise ValueError("manual_order cannot be negative")
        return v


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    priority: Optional[str] = None
    due_at: Optional[datetime] = None
    reminder_at: Optional[datetime] = None
    project_id: Optional[uuid.UUID] = None
    category: Optional[str] = None
    estimated_minutes: Optional[int] = None
    status: Optional[str] = None
    manual_order: Optional[int] = None

    @field_validator("status")
    @classmethod
    def status_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if v not in ("pending", "next", "in_progress", "waiting", "completed"):
            raise ValueError("Unsupported task status")
        return v

    @field_validator("manual_order")
    @classmethod
    def manual_order_valid(cls, v: int | None) -> int | None:
        if v is not None and v < 0:
            raise ValueError("manual_order cannot be negative")
        return v


class TaskReorderRequest(BaseModel):
    task_ids: List[uuid.UUID]

    @field_validator("task_ids")
    @classmethod
    def task_ids_valid(cls, v: list[uuid.UUID]) -> list[uuid.UUID]:
        if not v:
            raise ValueError("task_ids cannot be empty")
        if len(v) > 200:
            raise ValueError("Cannot reorder more than 200 tasks at once")
        if len(set(v)) != len(v):
            raise ValueError("task_ids must be unique")
        return v


class TaskCompletionEventResponse(BaseModel):
    id: uuid.UUID
    task_id: uuid.UUID
    event_type: str
    previous_status: Optional[str]
    next_status: str
    occurred_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class TaskResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    project_id: Optional[uuid.UUID]
    title: str
    description: Optional[str]
    priority: str
    status: str
    due_at: Optional[datetime]
    reminder_at: Optional[datetime]
    category: Optional[str]
    estimated_minutes: Optional[int]
    manual_order: int
    is_deleted: bool
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    subtasks: List[SubtaskResponse] = []

    model_config = {"from_attributes": True}
