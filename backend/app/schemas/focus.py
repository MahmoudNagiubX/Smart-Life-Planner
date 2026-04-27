import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator


class FocusSessionCreate(BaseModel):
    planned_minutes: int
    session_type: Optional[str] = "pomodoro"
    task_id: Optional[uuid.UUID] = None

    @field_validator("planned_minutes")
    @classmethod
    def minutes_valid(cls, v: int) -> int:
        if v < 1 or v > 480:
            raise ValueError("planned_minutes must be between 1 and 480")
        return v

    @field_validator("session_type")
    @classmethod
    def type_valid(cls, v: str) -> str:
        if v not in ("pomodoro", "deep_work", "short_break", "long_break"):
            raise ValueError("Invalid session_type")
        return v


class FocusSessionResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    task_id: Optional[uuid.UUID]
    session_type: str
    planned_minutes: int
    actual_minutes: Optional[int]
    status: str
    notes: Optional[str]
    started_at: datetime
    ended_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class FocusAnalyticsResponse(BaseModel):
    today_minutes: int
    today_sessions: int
    week_minutes: int
    week_sessions: int
    completed_sessions: int
    current_streak_days: int
    longest_streak_days: int
    average_session_minutes: int
    report_summary: str
