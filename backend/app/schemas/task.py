import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator, model_validator

VALID_TASK_STATUSES = {
    "pending",
    "next",
    "in_progress",
    "waiting",
    "someday",
    "completed",
}


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
    status: Optional[str] = "pending"
    due_at: Optional[datetime] = None
    start_date: Optional[datetime] = None
    reminder_at: Optional[datetime] = None
    project_id: Optional[uuid.UUID] = None
    category: Optional[str] = None
    estimated_minutes: Optional[int] = None
    estimated_duration_minutes: Optional[int] = None
    estimated_pomodoros: Optional[int] = None
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

    @field_validator("status")
    @classmethod
    def create_status_valid(cls, v: str | None) -> str:
        if v is None:
            return "pending"
        if v not in VALID_TASK_STATUSES - {"completed"}:
            raise ValueError("Unsupported task status")
        return v

    @field_validator("manual_order")
    @classmethod
    def manual_order_valid(cls, v: int | None) -> int:
        if v is None:
            return 0
        if v < 0:
            raise ValueError("manual_order cannot be negative")
        return v

    @field_validator("estimated_minutes", "estimated_duration_minutes")
    @classmethod
    def estimate_valid(cls, v: int | None) -> int | None:
        if v is not None and v < 0:
            raise ValueError("estimated duration cannot be negative")
        return v

    @field_validator("estimated_pomodoros")
    @classmethod
    def pomodoro_estimate_valid(cls, v: int | None) -> int | None:
        if v is not None and (v < 0 or v > 99):
            raise ValueError("estimated_pomodoros must be between 0 and 99")
        return v

    @model_validator(mode="after")
    def timeline_dates_valid(self) -> "TaskCreate":
        if self.start_date is not None and self.due_at is not None:
            try:
                if self.start_date > self.due_at:
                    raise ValueError("start_date cannot be after due_at")
            except TypeError as exc:
                raise ValueError("start_date and due_at must use compatible timezones") from exc
        if self.estimated_minutes is None and self.estimated_duration_minutes is not None:
            self.estimated_minutes = self.estimated_duration_minutes
        return self


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    priority: Optional[str] = None
    due_at: Optional[datetime] = None
    start_date: Optional[datetime] = None
    reminder_at: Optional[datetime] = None
    project_id: Optional[uuid.UUID] = None
    category: Optional[str] = None
    estimated_minutes: Optional[int] = None
    estimated_duration_minutes: Optional[int] = None
    estimated_pomodoros: Optional[int] = None
    completed_pomodoros: Optional[int] = None
    status: Optional[str] = None
    manual_order: Optional[int] = None

    @field_validator("status")
    @classmethod
    def status_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if v not in VALID_TASK_STATUSES:
            raise ValueError("Unsupported task status")
        return v

    @field_validator("manual_order")
    @classmethod
    def manual_order_valid(cls, v: int | None) -> int | None:
        if v is not None and v < 0:
            raise ValueError("manual_order cannot be negative")
        return v

    @field_validator("estimated_minutes", "estimated_duration_minutes")
    @classmethod
    def update_estimate_valid(cls, v: int | None) -> int | None:
        if v is not None and v < 0:
            raise ValueError("estimated duration cannot be negative")
        return v

    @field_validator("estimated_pomodoros")
    @classmethod
    def update_pomodoro_estimate_valid(cls, v: int | None) -> int | None:
        if v is not None and (v < 0 or v > 99):
            raise ValueError("estimated_pomodoros must be between 0 and 99")
        return v

    @field_validator("completed_pomodoros")
    @classmethod
    def completed_pomodoros_valid(cls, v: int | None) -> int | None:
        if v is not None and (v < 0 or v > 999):
            raise ValueError("completed_pomodoros must be between 0 and 999")
        return v

    @model_validator(mode="after")
    def update_timeline_dates_valid(self) -> "TaskUpdate":
        if self.start_date is not None and self.due_at is not None:
            try:
                if self.start_date > self.due_at:
                    raise ValueError("start_date cannot be after due_at")
            except TypeError as exc:
                raise ValueError("start_date and due_at must use compatible timezones") from exc
        if self.estimated_minutes is None and self.estimated_duration_minutes is not None:
            self.estimated_minutes = self.estimated_duration_minutes
        return self


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
    start_date: Optional[datetime] = None
    reminder_at: Optional[datetime]
    category: Optional[str]
    estimated_minutes: Optional[int]
    estimated_duration_minutes: Optional[int] = None
    estimated_pomodoros: int = 0
    completed_pomodoros: int = 0
    manual_order: int
    is_deleted: bool
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    subtasks: List[SubtaskResponse] = []

    model_config = {"from_attributes": True}


class ProjectTimelineDependencyResponse(BaseModel):
    task_id: uuid.UUID
    depends_on_task_id: uuid.UUID
    dependency_type: str


class ProjectTimelineTaskBarResponse(BaseModel):
    task_id: uuid.UUID
    title: str
    status: str
    priority: str
    project_id: uuid.UUID
    start_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = None
    dependency_ids: List[uuid.UUID] = []
    overdue: bool = False
    conflict: bool = False
    conflict_reasons: List[str] = []


class ProjectTimelineResponse(BaseModel):
    project: ProjectResponse
    task_bars: List[ProjectTimelineTaskBarResponse]
    dependencies: List[ProjectTimelineDependencyResponse] = []
