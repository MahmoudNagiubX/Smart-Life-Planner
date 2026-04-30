import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

ALLOWED_AMBIENT_SOUND_KEYS = {"silence", "rain", "cafe", "white_noise"}


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
    completion_rate_percent: int
    report_summary: str


class FocusSettingsResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    default_focus_minutes: int
    short_break_minutes: int
    long_break_minutes: int
    sessions_before_long_break: int
    continuous_mode_enabled: bool
    ambient_sound_key: str
    distraction_free_mode_enabled: bool
    updated_at: datetime

    model_config = {"from_attributes": True}


class FocusSettingsUpdate(BaseModel):
    default_focus_minutes: Optional[int] = Field(default=None, ge=5, le=180)
    short_break_minutes: Optional[int] = Field(default=None, ge=1, le=60)
    long_break_minutes: Optional[int] = Field(default=None, ge=5, le=120)
    sessions_before_long_break: Optional[int] = Field(default=None, ge=1, le=12)
    continuous_mode_enabled: Optional[bool] = None
    ambient_sound_key: Optional[str] = None
    distraction_free_mode_enabled: Optional[bool] = None

    @field_validator("ambient_sound_key")
    @classmethod
    def ambient_sound_supported(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in ALLOWED_AMBIENT_SOUND_KEYS:
            raise ValueError("Unsupported ambient sound")
        return normalized
