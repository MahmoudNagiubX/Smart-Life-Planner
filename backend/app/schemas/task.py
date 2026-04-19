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
    is_deleted: bool
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    subtasks: List[SubtaskResponse] = []

    model_config = {"from_attributes": True}