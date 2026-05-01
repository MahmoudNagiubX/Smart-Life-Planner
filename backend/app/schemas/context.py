import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


VALID_ENERGY_LEVELS = {"low", "medium", "high"}


class ContextSnapshotCreate(BaseModel):
    timezone: Optional[str] = Field(default=None, max_length=80)
    energy_level: Optional[str] = None
    coarse_location_context: Optional[str] = Field(default=None, max_length=120)
    weather_summary: Optional[str] = Field(default=None, max_length=160)
    device_context: Optional[str] = Field(default=None, max_length=160)

    @field_validator("timezone")
    @classmethod
    def timezone_valid(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("timezone cannot be empty")
        return cleaned

    @field_validator("energy_level")
    @classmethod
    def energy_level_valid(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip().lower()
        if normalized not in VALID_ENERGY_LEVELS:
            raise ValueError("Unsupported energy_level")
        return normalized

    @field_validator(
        "coarse_location_context",
        "weather_summary",
        "device_context",
    )
    @classmethod
    def optional_text_clean(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        return cleaned or None


class ContextSnapshotResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    timestamp: datetime
    timezone: str
    local_time_block: str
    energy_level: Optional[str]
    coarse_location_context: Optional[str]
    weather_summary: Optional[str]
    device_context: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TimeContextRecommendationItem(BaseModel):
    task_type: str
    title: str
    reason: str
    suggested_energy: str
    preference_match: bool = False


class TimeContextRecommendationResponse(BaseModel):
    local_time_block: str
    energy_level: str
    goal_tags: list[str]
    recommendations: list[TimeContextRecommendationItem]
    explanation: str
