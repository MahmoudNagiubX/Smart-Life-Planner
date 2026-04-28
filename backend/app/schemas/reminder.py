from datetime import datetime
from typing import Optional
import uuid

from pydantic import BaseModel, field_validator, model_validator
from app.services.task_reminder_presets import TASK_REMINDER_PRESETS


VALID_TARGET_TYPES = {
    "task",
    "habit",
    "note",
    "quran_goal",
    "prayer",
    "focus",
    "bedtime",
    "ai_suggestion",
    "location",
}
TARGET_TYPES_REQUIRING_ID = {"task", "habit", "note", "quran_goal", "focus"}
VALID_REMINDER_TYPES = {
    "task_due",
    "habit",
    "note",
    "quran_goal",
    "prayer",
    "focus_prompt",
    "bedtime",
    "ai_suggestion",
    "location",
}
VALID_REMINDER_STATUSES = {"scheduled", "sent", "snoozed", "cancelled", "failed"}
VALID_REMINDER_CHANNELS = {"local", "push", "in_app", "email"}
VALID_REMINDER_PRIORITIES = {"low", "normal", "high", "urgent"}


class ReminderCreate(BaseModel):
    target_type: str
    target_id: Optional[uuid.UUID] = None
    reminder_type: str
    scheduled_at: datetime
    recurrence_rule: Optional[str] = None
    timezone: str = "UTC"
    status: str = "scheduled"
    snooze_until: Optional[datetime] = None
    channel: str = "local"
    priority: str = "normal"

    @field_validator("target_type")
    @classmethod
    def target_type_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_TARGET_TYPES:
            raise ValueError("Unsupported reminder target_type")
        return normalized

    @field_validator("reminder_type")
    @classmethod
    def reminder_type_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_TYPES:
            raise ValueError("Unsupported reminder_type")
        return normalized

    @field_validator("scheduled_at", "snooze_until")
    @classmethod
    def datetime_must_be_timezone_aware(
        cls, value: Optional[datetime]
    ) -> Optional[datetime]:
        if value is not None and value.tzinfo is None:
            raise ValueError("Reminder datetimes must include timezone info")
        return value

    @field_validator("timezone")
    @classmethod
    def timezone_valid(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("timezone cannot be empty")
        return normalized

    @field_validator("status")
    @classmethod
    def status_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_STATUSES:
            raise ValueError("Unsupported reminder status")
        return normalized

    @field_validator("channel")
    @classmethod
    def channel_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_CHANNELS:
            raise ValueError("Unsupported reminder channel")
        return normalized

    @field_validator("priority")
    @classmethod
    def priority_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_PRIORITIES:
            raise ValueError("Unsupported reminder priority")
        return normalized

    @model_validator(mode="after")
    def target_id_required_for_owned_targets(self) -> "ReminderCreate":
        if self.target_type in TARGET_TYPES_REQUIRING_ID and self.target_id is None:
            raise ValueError("target_id is required for this reminder target_type")
        return self


class ReminderUpdate(BaseModel):
    scheduled_at: Optional[datetime] = None
    recurrence_rule: Optional[str] = None
    timezone: Optional[str] = None
    status: Optional[str] = None
    snooze_until: Optional[datetime] = None
    channel: Optional[str] = None
    priority: Optional[str] = None
    cancelled_at: Optional[datetime] = None

    @field_validator("scheduled_at", "snooze_until", "cancelled_at")
    @classmethod
    def update_datetime_must_be_timezone_aware(
        cls, value: Optional[datetime]
    ) -> Optional[datetime]:
        if value is not None and value.tzinfo is None:
            raise ValueError("Reminder datetimes must include timezone info")
        return value

    @field_validator("timezone")
    @classmethod
    def update_timezone_valid(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        normalized = value.strip()
        if not normalized:
            raise ValueError("timezone cannot be empty")
        return normalized

    @field_validator("status")
    @classmethod
    def update_status_valid(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_STATUSES:
            raise ValueError("Unsupported reminder status")
        return normalized

    @field_validator("channel")
    @classmethod
    def update_channel_valid(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_CHANNELS:
            raise ValueError("Unsupported reminder channel")
        return normalized

    @field_validator("priority")
    @classmethod
    def update_priority_valid(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_PRIORITIES:
            raise ValueError("Unsupported reminder priority")
        return normalized


class ReminderSnoozeRequest(BaseModel):
    minutes: int

    @field_validator("minutes")
    @classmethod
    def minutes_valid(cls, value: int) -> int:
        if value not in {10, 60}:
            raise ValueError("Snooze minutes must be 10 or 60")
        return value


class ReminderRescheduleRequest(BaseModel):
    scheduled_at: datetime

    @field_validator("scheduled_at")
    @classmethod
    def reschedule_datetime_must_be_timezone_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("scheduled_at must include timezone info")
        return value


class ReminderResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    target_type: str
    target_id: Optional[uuid.UUID]
    reminder_type: str
    scheduled_at: datetime
    recurrence_rule: Optional[str]
    timezone: str
    status: str
    snooze_until: Optional[datetime]
    channel: str
    priority: str
    created_at: datetime
    updated_at: datetime
    cancelled_at: Optional[datetime]

    model_config = {"from_attributes": True}


class TaskReminderPresetItem(BaseModel):
    preset: str
    custom_scheduled_at: Optional[datetime] = None
    custom_recurrence_rule: Optional[str] = None
    channel: str = "local"
    priority: str = "normal"

    @field_validator("preset")
    @classmethod
    def preset_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in TASK_REMINDER_PRESETS:
            raise ValueError("Unsupported task reminder preset")
        return normalized

    @field_validator("custom_scheduled_at")
    @classmethod
    def custom_datetime_must_be_timezone_aware(
        cls, value: Optional[datetime]
    ) -> Optional[datetime]:
        if value is not None and value.tzinfo is None:
            raise ValueError("custom_scheduled_at must include timezone info")
        return value

    @field_validator("custom_recurrence_rule")
    @classmethod
    def custom_rule_trimmed(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        stripped = value.strip()
        return stripped or None

    @field_validator("channel")
    @classmethod
    def preset_channel_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_CHANNELS:
            raise ValueError("Unsupported reminder channel")
        return normalized

    @field_validator("priority")
    @classmethod
    def preset_priority_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in VALID_REMINDER_PRIORITIES:
            raise ValueError("Unsupported reminder priority")
        return normalized

    @model_validator(mode="after")
    def custom_fields_valid(self) -> "TaskReminderPresetItem":
        if self.preset in {"custom", "recurring_custom"} and (
            self.custom_scheduled_at is None
        ):
            raise ValueError("custom_scheduled_at is required for this preset")
        if self.preset == "recurring_custom" and not self.custom_recurrence_rule:
            raise ValueError("custom_recurrence_rule is required")
        return self


class TaskReminderPresetRequest(BaseModel):
    task_id: uuid.UUID
    presets: list[TaskReminderPresetItem]
    timezone: str = "UTC"

    @field_validator("presets")
    @classmethod
    def presets_not_empty(
        cls, value: list[TaskReminderPresetItem]
    ) -> list[TaskReminderPresetItem]:
        if not value:
            raise ValueError("At least one reminder preset is required")
        return value

    @field_validator("timezone")
    @classmethod
    def preset_timezone_valid(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("timezone cannot be empty")
        return normalized
