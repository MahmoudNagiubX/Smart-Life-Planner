from pydantic import BaseModel, ConfigDict
from pydantic import Field, field_validator
from typing import Literal, Optional
import uuid
from datetime import datetime
from app.core.reminder_preferences import default_reminder_preferences
from app.services.onboarding_defaults import normalize_goal_keys

ALLOWED_ONBOARDING_GOALS = {
    "study",
    "work",
    "self_improvement",
    "fitness",
    "spiritual_growth",
}

ALLOWED_PRAYER_METHODS = {
    "MWL",
    "Egypt",
    "Makkah",
    "ISNA",
    "Karachi",
}
DEFAULT_DASHBOARD_WIDGETS = [
    "top_tasks",
    "next_prayer",
    "habit_snapshot",
    "journal_prompt",
    "ai_plan",
    "focus_shortcut",
    "productivity_score",
    "quran_goal",
]
ALLOWED_DASHBOARD_WIDGETS = set(DEFAULT_DASHBOARD_WIDGETS)


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


def _validate_goal_contract(goals: list[str]) -> list[str]:
    normalized = normalize_goal_keys(goals)
    unsupported = [
        goal for goal in normalized if goal not in ALLOWED_ONBOARDING_GOALS
    ]
    if unsupported:
        raise ValueError(
            "Unsupported onboarding goals: " + ", ".join(sorted(unsupported))
        )
    return normalized


def validate_dashboard_widgets(widgets: list[str] | None) -> list[str] | None:
    if widgets is None:
        return widgets
    normalized: list[str] = []
    seen: set[str] = set()
    for widget in widgets:
        clean = widget.strip().lower()
        if clean not in ALLOWED_DASHBOARD_WIDGETS:
            raise ValueError(f"Unsupported dashboard widget: {widget}")
        if clean not in seen:
            seen.add(clean)
            normalized.append(clean)
    return normalized


class ReminderChannels(BaseModel):
    model_config = ConfigDict(extra="forbid")

    local: bool = True
    push: bool = True
    in_app: bool = True
    email: bool = False


class ReminderTypes(BaseModel):
    model_config = ConfigDict(extra="forbid")

    task: bool = True
    habit: bool = True
    note: bool = True
    quran_goal: bool = True
    prayer: bool = True
    focus_prompt: bool = True
    bedtime: bool = True
    ai_suggestion: bool = True
    location: bool = False
    constant_reminders: bool = True


class ReminderQuietHours(BaseModel):
    model_config = ConfigDict(extra="forbid")

    enabled: bool = False
    start: str = "22:00"
    end: str = "07:00"

    @field_validator("start")
    @classmethod
    def start_valid(cls, value: str) -> str:
        checked = _validate_hh_mm(value, "quiet_hours.start")
        if checked is None:
            raise ValueError("quiet_hours.start is required")
        return checked

    @field_validator("end")
    @classmethod
    def end_valid(cls, value: str) -> str:
        checked = _validate_hh_mm(value, "quiet_hours.end")
        if checked is None:
            raise ValueError("quiet_hours.end is required")
        return checked


class ReminderTiming(BaseModel):
    model_config = ConfigDict(extra="forbid")

    prayer_minutes_before: int = Field(default=10, ge=0, le=120)
    bedtime_minutes_before: int = Field(default=30, ge=0, le=240)
    focus_prompt_minutes_before: int = Field(default=10, ge=0, le=240)


class ReminderPreferences(BaseModel):
    model_config = ConfigDict(extra="forbid")

    channels: ReminderChannels = Field(default_factory=ReminderChannels)
    types: ReminderTypes = Field(default_factory=ReminderTypes)
    quiet_hours: ReminderQuietHours = Field(default_factory=ReminderQuietHours)
    timing: ReminderTiming = Field(default_factory=ReminderTiming)


class WorkStudyWindow(BaseModel):
    """Structured JSON payload for first-run work or study availability."""

    model_config = ConfigDict(extra="forbid")

    window_type: Literal["work", "study", "custom"] = "custom"
    label: Optional[str] = Field(default=None, max_length=80)
    start_time: str
    end_time: str
    days: list[int] = Field(default_factory=list)

    @field_validator("label")
    @classmethod
    def label_trimmed(cls, value: str | None) -> str | None:
        if value is None:
            return value
        stripped = value.strip()
        return stripped or None

    @field_validator("start_time")
    @classmethod
    def start_time_valid(cls, value: str) -> str:
        checked = _validate_hh_mm(value, "start_time")
        if checked is None:
            raise ValueError("start_time is required")
        return checked

    @field_validator("end_time")
    @classmethod
    def end_time_valid(cls, value: str) -> str:
        checked = _validate_hh_mm(value, "end_time")
        if checked is None:
            raise ValueError("end_time is required")
        return checked

    @field_validator("days")
    @classmethod
    def days_valid(cls, value: list[int]) -> list[int]:
        seen: set[int] = set()
        normalized: list[int] = []
        for day in value:
            if day < 0 or day > 6:
                raise ValueError("days must use integers 0 through 6")
            if day not in seen:
                seen.add(day)
                normalized.append(day)
        return normalized


class SettingsResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    timezone: str
    language: str
    prayer_calculation_method: str
    prayer_location_lat: Optional[float]
    prayer_location_lng: Optional[float]
    prayer_reminder_minutes_before: int
    athan_sound_enabled: bool
    theme: str
    notifications_enabled: bool
    reminder_preferences: ReminderPreferences = Field(
        default_factory=lambda: ReminderPreferences(
            **default_reminder_preferences()
        )
    )

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
    ai_goal_tags: list[str]
    ai_daily_rhythm: dict
    ai_recommendation_seeded_at: Optional[datetime]
    dashboard_widgets: list[str]
    ramadan_mode_enabled: bool
    suhoor_reminder_enabled: bool
    suhoor_reminder_minutes_before_fajr: int

    updated_at: datetime

    model_config = {"from_attributes": True}


class SettingsUpdate(BaseModel):
    timezone: Optional[str] = None
    language: Optional[str] = None
    prayer_calculation_method: Optional[str] = None
    prayer_location_lat: Optional[float] = None
    prayer_location_lng: Optional[float] = None
    prayer_reminder_minutes_before: Optional[int] = Field(
        default=None, ge=0, le=120
    )
    athan_sound_enabled: Optional[bool] = None
    theme: Optional[str] = None
    notifications_enabled: Optional[bool] = None
    reminder_preferences: Optional[ReminderPreferences] = None

    country: Optional[str] = None
    city: Optional[str] = None
    goals: Optional[list[str]] = Field(default=None)
    wake_time: Optional[str] = None
    sleep_time: Optional[str] = None
    work_study_windows: Optional[list[WorkStudyWindow]] = Field(default=None)
    microphone_enabled: Optional[bool] = None
    location_enabled: Optional[bool] = None
    onboarding_completed: Optional[bool] = None
    dashboard_widgets: Optional[list[str]] = None
    ramadan_mode_enabled: Optional[bool] = None
    suhoor_reminder_enabled: Optional[bool] = None
    suhoor_reminder_minutes_before_fajr: Optional[int] = Field(
        default=None, ge=0, le=240
    )

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
        return _validate_goal_contract(value)

    @field_validator("prayer_calculation_method")
    @classmethod
    def prayer_method_supported(cls, value: str | None) -> str | None:
        if value is not None and value not in ALLOWED_PRAYER_METHODS:
            raise ValueError("Unsupported prayer calculation method")
        return value

    @field_validator("dashboard_widgets")
    @classmethod
    def dashboard_widgets_valid(cls, value: list[str] | None) -> list[str] | None:
        return validate_dashboard_widgets(value)


class OnboardingRequest(BaseModel):
    timezone: str
    language: str
    prayer_calculation_method: str
    country: Optional[str] = Field(default=None, max_length=100)
    city: Optional[str] = Field(default=None, max_length=100)
    goals: list[str] = Field(default_factory=list)
    wake_time: Optional[str] = None
    sleep_time: Optional[str] = None
    work_study_windows: list[WorkStudyWindow] = Field(default_factory=list)
    notifications_enabled: bool = True
    microphone_enabled: bool = False
    location_enabled: bool = False

    @field_validator("timezone", "prayer_calculation_method")
    @classmethod
    def required_text_not_empty(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Value cannot be empty")
        return value.strip()

    @field_validator("prayer_calculation_method")
    @classmethod
    def onboarding_prayer_method_supported(cls, value: str) -> str:
        if value not in ALLOWED_PRAYER_METHODS:
            raise ValueError("Unsupported prayer calculation method")
        return value

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
        return _validate_goal_contract(value)

    @field_validator("wake_time")
    @classmethod
    def onboarding_wake_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "wake_time")

    @field_validator("sleep_time")
    @classmethod
    def onboarding_sleep_time_valid(cls, value: str | None) -> str | None:
        return _validate_hh_mm(value, "sleep_time")
