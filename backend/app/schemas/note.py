import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


class NoteCreate(BaseModel):
    title: Optional[str] = None
    content: str
    note_type: Optional[str] = "text"
    tags: Optional[List[str]] = None

    @field_validator("content")
    @classmethod
    def content_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Content cannot be empty")
        return v.strip()

    @field_validator("note_type")
    @classmethod
    def note_type_valid(cls, v: str) -> str:
        if v not in ("text", "checklist", "voice"):
            raise ValueError("note_type must be text, checklist, or voice")
        return v


class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_pinned: Optional[bool] = None
    is_archived: Optional[bool] = None


class NoteResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: Optional[str]
    content: str
    note_type: str
    tags: Optional[list]
    is_pinned: bool
    is_archived: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}