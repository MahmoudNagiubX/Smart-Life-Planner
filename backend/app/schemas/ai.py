from datetime import date, datetime
from pydantic import BaseModel, Field, field_validator
from typing import Optional

class ParseTaskRequest(BaseModel):
    input_text: str

    @field_validator("input_text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("input_text cannot be empty")
        return v.strip()

class ParseTaskResponse(BaseModel):
    success: bool
    data: dict
    raw_input: str
    requires_confirmation: bool = True
    parse_status: str = "parsed"
    fallback_reason: Optional[str] = None

class NextActionResponse(BaseModel):
    task_id: Optional[str]
    title: Optional[str]
    reason: str
    confidence: str

class DailyPlanRequest(BaseModel):
    date: Optional[str] = None

class DailyPlanItem(BaseModel):
    task_id: str
    title: str
    suggested_time: str
    duration_minutes: int
    reason: str

class DailyPlanResponse(BaseModel):
    date: str
    plan: list[DailyPlanItem]

class QuickCaptureClassifyRequest(BaseModel):
    input_text: str

    @field_validator("input_text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("input_text cannot be empty")
        return v.strip()

class QuickCaptureClassifyResponse(BaseModel):
    capture_type: str
    confidence: str
    title: str
    content: str
    checklist_items: list[str] = []
    reminder_at: Optional[datetime] = None
    reason: str


class GoalRoadmapRequest(BaseModel):
    goal_title: str
    deadline: Optional[date] = None
    current_level: Optional[str] = Field(default=None, max_length=80)
    weekly_available_hours: int = Field(ge=1, le=40)
    constraints: Optional[str] = Field(default=None, max_length=500)

    @field_validator("goal_title")
    @classmethod
    def goal_title_not_empty(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("goal_title cannot be empty")
        return cleaned

    @field_validator("current_level", "constraints")
    @classmethod
    def optional_text_clean(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        return cleaned or None


class GoalRoadmapMilestone(BaseModel):
    index: int
    title: str
    description: str
    target_week: int


class GoalRoadmapTask(BaseModel):
    milestone_index: int
    title: str
    description: str
    priority: str
    estimated_minutes: int
    suggested_week: int


class GoalRoadmapResponse(BaseModel):
    goal_title: str
    deadline: Optional[date]
    milestones: list[GoalRoadmapMilestone]
    suggested_tasks: list[GoalRoadmapTask]
    schedule_suggestion: str
    confidence: str
    requires_confirmation: bool = True
    fallback_used: bool = True
