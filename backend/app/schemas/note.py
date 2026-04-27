import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator, model_validator

ALLOWED_NOTE_COLORS = {
    "default",
    "red",
    "orange",
    "yellow",
    "green",
    "blue",
    "purple",
}


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


def _normalize_color_key(color_key: str | None) -> str | None:
    if color_key is None:
        return None
    clean = color_key.strip().lower()
    if clean not in ALLOWED_NOTE_COLORS:
        raise ValueError("Unsupported note color")
    return clean


class NoteChecklistItem(BaseModel):
    id: str
    text: str
    is_completed: bool = False

    @field_validator("id")
    @classmethod
    def id_not_empty(cls, v: str) -> str:
        clean = v.strip()
        if not clean:
            raise ValueError("Checklist item id cannot be empty")
        if len(clean) > 80:
            raise ValueError("Checklist item id is too long")
        return clean

    @field_validator("text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        clean = v.strip()
        if not clean:
            raise ValueError("Checklist item text cannot be empty")
        if len(clean) > 500:
            raise ValueError("Checklist item text must be 500 characters or fewer")
        return clean


class NoteStructuredBlock(BaseModel):
    id: str
    type: str
    text: Optional[str] = None
    items: Optional[List[NoteChecklistItem | str]] = None
    reminder_at: Optional[datetime] = None
    task_id: Optional[str] = None
    task_title: Optional[str] = None

    @field_validator("id")
    @classmethod
    def id_not_empty(cls, v: str) -> str:
        clean = v.strip()
        if not clean:
            raise ValueError("Structured block id cannot be empty")
        if len(clean) > 80:
            raise ValueError("Structured block id is too long")
        return clean

    @field_validator("type")
    @classmethod
    def type_valid(cls, v: str) -> str:
        clean = v.strip().lower()
        if clean not in (
            "paragraph",
            "bullet_list",
            "checklist",
            "reminder",
            "task_link",
        ):
            raise ValueError("Unsupported structured block type")
        return clean

    @field_validator("text", "task_id", "task_title")
    @classmethod
    def optional_text_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        clean = v.strip()
        if len(clean) > 1000:
            raise ValueError("Structured block text is too long")
        return clean or None


def _normalize_checklist_items(
    items: list[NoteChecklistItem] | None,
) -> list[NoteChecklistItem] | None:
    if items is None:
        return None
    seen: set[str] = set()
    for item in items:
        if item.id in seen:
            raise ValueError("Checklist item ids must be unique")
        seen.add(item.id)
    return items


def _normalize_structured_blocks(
    blocks: list[NoteStructuredBlock] | None,
) -> list[NoteStructuredBlock] | None:
    if blocks is None:
        return None
    seen: set[str] = set()
    for block in blocks:
        if block.id in seen:
            raise ValueError("Structured block ids must be unique")
        seen.add(block.id)
    return blocks


class NoteAttachmentPayload(BaseModel):
    file_url: Optional[str] = None
    local_path: Optional[str] = None
    file_type: str
    file_size: int = 0

    @model_validator(mode="after")
    def has_location(self) -> "NoteAttachmentPayload":
        if not self.file_url and not self.local_path:
            raise ValueError("Attachment requires file_url or local_path")
        return self

    @field_validator("file_url", "local_path")
    @classmethod
    def optional_path_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        clean = v.strip()
        if len(clean) > 1024:
            raise ValueError("Attachment path is too long")
        return clean or None

    @field_validator("file_type")
    @classmethod
    def file_type_valid(cls, v: str) -> str:
        clean = v.strip().lower()
        if clean not in ("image/jpeg", "image/png", "image/webp", "image/heic"):
            raise ValueError("Unsupported attachment type")
        return clean

    @field_validator("file_size")
    @classmethod
    def file_size_valid(cls, v: int) -> int:
        if v < 0:
            raise ValueError("Attachment size cannot be negative")
        if v > 15 * 1024 * 1024:
            raise ValueError("Attachment image is too large")
        return v


class NoteAttachmentResponse(BaseModel):
    id: uuid.UUID
    note_id: uuid.UUID
    file_url: Optional[str]
    local_path: Optional[str]
    file_type: str
    file_size: int
    created_at: datetime

    model_config = {"from_attributes": True}


class NoteCreate(BaseModel):
    title: Optional[str] = None
    content: str
    note_type: Optional[str] = "text"
    tags: Optional[List[str]] = None
    checklist_items: Optional[List[NoteChecklistItem]] = None
    structured_blocks: Optional[List[NoteStructuredBlock]] = None
    attachments: Optional[List[NoteAttachmentPayload]] = None
    color_key: Optional[str] = "default"

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

    @field_validator("color_key")
    @classmethod
    def color_key_valid(cls, v: str | None) -> str | None:
        return _normalize_color_key(v)

    @field_validator("checklist_items")
    @classmethod
    def checklist_items_valid(
        cls, v: list[NoteChecklistItem] | None
    ) -> list[NoteChecklistItem] | None:
        return _normalize_checklist_items(v)

    @field_validator("structured_blocks")
    @classmethod
    def structured_blocks_valid(
        cls, v: list[NoteStructuredBlock] | None
    ) -> list[NoteStructuredBlock] | None:
        return _normalize_structured_blocks(v)


class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    note_type: Optional[str] = None
    tags: Optional[List[str]] = None
    checklist_items: Optional[List[NoteChecklistItem]] = None
    structured_blocks: Optional[List[NoteStructuredBlock]] = None
    attachments: Optional[List[NoteAttachmentPayload]] = None
    color_key: Optional[str] = None
    is_pinned: Optional[bool] = None
    is_archived: Optional[bool] = None

    @field_validator("tags")
    @classmethod
    def tags_valid(cls, v: list[str] | None) -> list[str] | None:
        return _normalize_tags(v)

    @field_validator("note_type")
    @classmethod
    def note_type_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        if v not in ("text", "checklist", "voice"):
            raise ValueError("note_type must be text, checklist, or voice")
        return v

    @field_validator("color_key")
    @classmethod
    def color_key_valid(cls, v: str | None) -> str | None:
        return _normalize_color_key(v)

    @field_validator("checklist_items")
    @classmethod
    def checklist_items_valid(
        cls, v: list[NoteChecklistItem] | None
    ) -> list[NoteChecklistItem] | None:
        return _normalize_checklist_items(v)

    @field_validator("structured_blocks")
    @classmethod
    def structured_blocks_valid(
        cls, v: list[NoteStructuredBlock] | None
    ) -> list[NoteStructuredBlock] | None:
        return _normalize_structured_blocks(v)


class NoteResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: Optional[str]
    content: str
    note_type: str
    tags: Optional[list]
    checklist_items: Optional[list]
    structured_blocks: Optional[list]
    attachments: list[NoteAttachmentResponse] = []
    color_key: str
    is_pinned: bool
    is_archived: bool
    archived_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
