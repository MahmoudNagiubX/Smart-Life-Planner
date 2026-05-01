import uuid
from datetime import datetime, time
from typing import Optional

from pydantic import BaseModel, field_validator


SUPPORTED_DHIKR_RECURRENCE = {"once", "daily", "weekdays"}


class DhikrReminderCreate(BaseModel):
    title: str
    phrase: Optional[str] = None
    schedule_time: time
    recurrence_rule: str = "daily"
    timezone: str = "UTC"
    enabled: bool = True

    @field_validator("title")
    @classmethod
    def title_valid(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("title cannot be empty")
        if len(normalized) > 120:
            raise ValueError("title is too long")
        return normalized

    @field_validator("phrase")
    @classmethod
    def phrase_valid(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip()
        return normalized or None

    @field_validator("recurrence_rule")
    @classmethod
    def recurrence_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in SUPPORTED_DHIKR_RECURRENCE:
            raise ValueError("Unsupported dhikr recurrence_rule")
        return normalized

    @field_validator("timezone")
    @classmethod
    def timezone_valid(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("timezone cannot be empty")
        return normalized


class DhikrReminderUpdate(BaseModel):
    title: Optional[str] = None
    phrase: Optional[str] = None
    schedule_time: Optional[time] = None
    recurrence_rule: Optional[str] = None
    timezone: Optional[str] = None
    enabled: Optional[bool] = None

    @field_validator("title")
    @classmethod
    def update_title_valid(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip()
        if not normalized:
            raise ValueError("title cannot be empty")
        if len(normalized) > 120:
            raise ValueError("title is too long")
        return normalized

    @field_validator("phrase")
    @classmethod
    def update_phrase_valid(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip()
        return normalized or None

    @field_validator("recurrence_rule")
    @classmethod
    def update_recurrence_valid(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in SUPPORTED_DHIKR_RECURRENCE:
            raise ValueError("Unsupported dhikr recurrence_rule")
        return normalized

    @field_validator("timezone")
    @classmethod
    def update_timezone_valid(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.strip()
        if not normalized:
            raise ValueError("timezone cannot be empty")
        return normalized


class DhikrReminderResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    phrase: Optional[str]
    schedule_time: time
    recurrence_rule: str
    timezone: str
    enabled: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
