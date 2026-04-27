import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


def _normalize_tags(tags: list[str] | None) -> list[str] | None:
    if tags is None:
        return None
    normalized: list[str] = []
    seen: set[str] = set()
    for tag in tags:
        clean = tag.strip().lower().lstrip("#")
        if not clean:
            continue
        if len(clean) > 40:
            raise ValueError("Tags must be 40 characters or fewer")
        if clean not in seen:
            seen.add(clean)
            normalized.append(clean)
    return normalized


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

    @field_validator("tags")
    @classmethod
    def tags_valid(cls, v: list[str] | None) -> list[str] | None:
        return _normalize_tags(v)


class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_pinned: Optional[bool] = None
    is_archived: Optional[bool] = None

    @field_validator("tags")
    @classmethod
    def tags_valid(cls, v: list[str] | None) -> list[str] | None:
        return _normalize_tags(v)


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
