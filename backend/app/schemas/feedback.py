import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

FeedbackCategory = Literal["bug", "idea", "account", "reminder", "ai", "other"]


class FeedbackCreate(BaseModel):
    category: FeedbackCategory
    message: str = Field(min_length=10, max_length=2000)
    app_version: str | None = Field(default=None, max_length=40)
    device_context: str | None = Field(default=None, max_length=160)

    @field_validator("message")
    @classmethod
    def message_trimmed(cls, value: str) -> str:
        stripped = " ".join(value.split())
        if len(stripped) < 10:
            raise ValueError("Feedback message must be at least 10 characters")
        return stripped

    @field_validator("app_version", "device_context")
    @classmethod
    def optional_text_trimmed(cls, value: str | None) -> str | None:
        if value is None:
            return value
        stripped = " ".join(value.split())
        return stripped or None


class FeedbackResponse(BaseModel):
    id: uuid.UUID
    category: str
    status: str
    created_at: datetime
    message: str = "Feedback received"

    model_config = {"from_attributes": True}
