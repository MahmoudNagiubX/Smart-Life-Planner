import uuid
from datetime import datetime, date, time
from typing import Any, Optional
from pydantic import BaseModel, field_validator


VALID_HABIT_CATEGORIES = {
    "study",
    "reading",
    "quran",
    "exercise",
    "hydration",
    "sleep",
    "meditation",
}


class HabitCreate(BaseModel):
    title: str
    description: Optional[str] = None
    frequency_type: Optional[str] = "daily"
    frequency_config: Optional[dict[str, Any]] = None
    category: Optional[str] = None
    emoji: Optional[str] = None
    reminder_time: Optional[time] = None

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Title cannot be empty")
        return v.strip()

    @field_validator("frequency_type")
    @classmethod
    def frequency_valid(cls, v: str) -> str:
        if v not in ("daily", "weekly", "custom"):
            raise ValueError("frequency_type must be daily, weekly, or custom")
        return v

    @field_validator("category")
    @classmethod
    def category_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        normalized = v.strip().lower()
        if normalized not in VALID_HABIT_CATEGORIES:
            raise ValueError("Invalid habit category")
        return normalized

    @field_validator("emoji")
    @classmethod
    def emoji_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        normalized = v.strip()
        if not normalized:
            return None
        if len(normalized) > 16:
            raise ValueError("Habit emoji must be short")
        return normalized


class HabitUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    frequency_type: Optional[str] = None
    frequency_config: Optional[dict[str, Any]] = None
    category: Optional[str] = None
    emoji: Optional[str] = None
    reminder_time: Optional[time] = None
    is_active: Optional[bool] = None

    @field_validator("frequency_type")
    @classmethod
    def update_frequency_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("daily", "weekly", "custom"):
            raise ValueError("frequency_type must be daily, weekly, or custom")
        return v

    @field_validator("category")
    @classmethod
    def update_category_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        normalized = v.strip().lower()
        if normalized not in VALID_HABIT_CATEGORIES:
            raise ValueError("Invalid habit category")
        return normalized

    @field_validator("emoji")
    @classmethod
    def update_emoji_valid(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        normalized = v.strip()
        if not normalized:
            return None
        if len(normalized) > 16:
            raise ValueError("Habit emoji must be short")
        return normalized


class HabitLogResponse(BaseModel):
    id: uuid.UUID
    habit_id: uuid.UUID
    log_date: date
    is_completed: bool
    completed_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class HabitResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    description: Optional[str]
    frequency_type: str
    frequency_config: Optional[dict[str, Any]]
    category: Optional[str]
    emoji: Optional[str]
    reminder_time: Optional[time]
    is_active: bool
    current_streak: int
    longest_streak: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
