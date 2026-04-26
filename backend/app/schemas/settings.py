from pydantic import BaseModel
from pydantic import Field, field_validator
from typing import Optional
import uuid
from datetime import datetime
from app.services.onboarding_defaults import normalize_goal_keys


def _validate_hh_mm(value: str | None, field_name: str) -> str | None:
    if value is None:
        return value
    parts = value.split(":")
    if len(parts) != 2:
        raise ValueError(f"{field_name} must use HH:MM format")
    hour, minute = parts
    if not (hour.isdigit() and minute.isdigit()):
        raise ValueError(f"{field_name} must use HH:MM format")
    hour_int = int(hour)
    minute_int = int(minute)
    if hour_int > 23 or minute_int > 59:
        raise ValueError(f"{field_name} must be a valid 24-hour time")
    return f"{hour_int:02d}:{minute_int:02d}"


class SettingsResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    timezone: str
    language: str
    prayer_calculation_method: str
    prayer_location_lat: Optional[float]
    prayer_location_lng: Optional[float]
    theme: str
    notifications_enabled: bool

    # Onboarding fields
    country: Optional[str]
    city: Optional[str]
    goals: list[str]
    wake_time: Optional[str]
    sleep_time: Optional[str]
    work_study_windows: list[dict]
    microphone_enabled: bool
    location_enabled: bool
    onboarding_completed: bool

    updated_at: datetime

    model_config = {"from_attributes": True}


class SettingsUpdate(BaseModel):
    timezone: Optional[str] = None
    language: Optional[str] = None
    prayer_calculation_method: Optional[str] = None
    prayer_location_lat: Optional[float] = None
    prayer_location_lng: Optional[float] = None
    theme: Optional[str] = None
    notifications_enabled: Optional[bool] = None

    country: Optional[str] = None
    city: Optional[str] = None
    goals: Optional[list[str]] = Field(default=None)
    wake_time: Optional[str] = None
    sleep_time: Optional[str] = None
    work_study_windows: Optional[list[dict]] = Field(default=None)
    microphone_enabled: Optional[bool] = None
    location_enabled: Optional[bool] = None
    onboarding_completed: Optional[bool] = None

    @field_validator("language")
    @classmethod
    def language_supported(cls, value: str | None) -> str | None:
        if value is not None and value not in {"en", "ar"}:
            raise ValueError("language must be en or ar")
        return value

    @field_validator("wake_time")
    @classmethod
    def wake_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "wake_time")

    @field_validator("sleep_time")
    @classmethod
    def sleep_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "sleep_time")

    @field_validator("goals")
    @classmethod
    def settings_goals_normalized(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return value
        return normalize_goal_keys(value)


class OnboardingRequest(BaseModel):
    timezone: str
    language: str
    prayer_calculation_method: str
    country: Optional[str] = None
    city: Optional[str] = None
    goals: list[str] = Field(default_factory=list)
    wake_time: Optional[str] = None
    sleep_time: Optional[str] = None
    work_study_windows: list[dict] = Field(default_factory=list)
    notifications_enabled: bool = True
    microphone_enabled: bool = False
    location_enabled: bool = False

    @field_validator("timezone", "prayer_calculation_method")
    @classmethod
    def required_text_not_empty(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Value cannot be empty")
        return value.strip()

    @field_validator("language")
    @classmethod
    def onboarding_language_supported(cls, value: str) -> str:
        if value not in {"en", "ar"}:
            raise ValueError("language must be en or ar")
        return value

    @field_validator("country", "city")
    @classmethod
    def optional_text_trimmed(cls, value: str | None) -> str | None:
        if value is None:
            return value
        stripped = value.strip()
        return stripped or None

    @field_validator("goals")
    @classmethod
    def goals_trimmed(cls, value: list[str]) -> list[str]:
        return normalize_goal_keys(value)

    @field_validator("wake_time")
    @classmethod
    def onboarding_wake_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "wake_time")

    @field_validator("sleep_time")
    @classmethod
    def onboarding_sleep_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "sleep_time")
