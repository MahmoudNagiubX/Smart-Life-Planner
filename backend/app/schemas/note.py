import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator, model_validator

ALLOWED_NOTE_COLORS = {
    "default",
    "red",
    "orange",
    "yellow",
    "green",
    "blue",
    "purple",
}
ALLOWED_NOTE_SOURCES = {"manual", "voice", "ai", "quick_capture"}
ALLOWED_SMART_NOTE_JOB_TYPES = {
    "ocr",
    "handwriting",
    "summary",
    "action_extraction",
}
ALLOWED_SMART_NOTE_JOB_STATUSES = {
    "pending",
    "processing",
    "completed",
    "failed",
}
ALLOWED_NOTE_SUMMARY_STYLES = {
    "short",
    "bullets",
    "study_notes",
    "action_focused",
}
ALLOWED_NOTE_ACTION_ITEM_TYPES = {
    "task",
    "reminder",
    "checklist_item",
    "calendar_suggestion",
    "focus_suggestion",
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


def _normalize_source_type(source_type: str | None) -> str | None:
    if source_type is None:
        return None
    clean = source_type.strip().lower()
    if clean not in ALLOWED_NOTE_SOURCES:
        raise ValueError("Unsupported note source")
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
    image_url: Optional[str] = None
    local_path: Optional[str] = None
    file_type: Optional[str] = None
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
            "heading",
            "paragraph",
            "bullet_list",
            "checklist",
            "divider",
            "image",
            "reminder",
            "task_link",
        ):
            raise ValueError("Unsupported structured block type")
        return clean

    @field_validator("text", "task_id", "task_title", "image_url", "local_path", "file_type")
    @classmethod
    def optional_text_valid(cls, v: str | None) -> str | None:
        if v is None:
            return None
        clean = v.strip()
        if len(clean) > 1000:
            raise ValueError("Structured block text is too long")
        return clean or None

    @model_validator(mode="after")
    def block_content_valid(self) -> "NoteStructuredBlock":
        if self.type in {"heading", "paragraph"} and not self.text:
            raise ValueError(f"{self.type} block requires text")
        if self.type == "bullet_list":
            if not self.items:
                raise ValueError("bullet_list block requires items")
            for item in self.items:
                if isinstance(item, str) and not item.strip():
                    raise ValueError("bullet_list item cannot be empty")
        if self.type == "checklist" and not self.items:
            raise ValueError("checklist block requires items")
        if self.type == "image" and not (self.image_url or self.local_path):
            raise ValueError("image block requires image_url or local_path")
        if self.type == "task_link" and not (self.task_id or self.task_title):
            raise ValueError("task_link block requires task_id or task_title")
        return self


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
    task_id: Optional[uuid.UUID] = None
    note_type: Optional[str] = "text"
    tags: Optional[List[str]] = None
    checklist_items: Optional[List[NoteChecklistItem]] = None
    structured_blocks: Optional[List[NoteStructuredBlock]] = None
    attachments: Optional[List[NoteAttachmentPayload]] = None
    reminder_at: Optional[datetime] = None
    source_type: Optional[str] = "manual"
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

    @field_validator("source_type")
    @classmethod
    def source_type_valid(cls, v: str | None) -> str | None:
        return _normalize_source_type(v)

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
    task_id: Optional[uuid.UUID] = None
    note_type: Optional[str] = None
    tags: Optional[List[str]] = None
    checklist_items: Optional[List[NoteChecklistItem]] = None
    structured_blocks: Optional[List[NoteStructuredBlock]] = None
    attachments: Optional[List[NoteAttachmentPayload]] = None
    reminder_at: Optional[datetime] = None
    clear_reminder_at: Optional[bool] = None
    source_type: Optional[str] = None
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

    @field_validator("source_type")
    @classmethod
    def source_type_valid(cls, v: str | None) -> str | None:
        return _normalize_source_type(v)

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
    task_id: Optional[uuid.UUID]
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
    reminder_at: Optional[datetime]
    source_type: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class NoteSummaryRequest(BaseModel):
    summary_style: str = "short"

    @field_validator("summary_style")
    @classmethod
    def summary_style_valid(cls, value: str) -> str:
        clean = value.strip().lower()
        if clean not in ALLOWED_NOTE_SUMMARY_STYLES:
            raise ValueError("Unsupported note summary style")
        return clean


class NoteSummaryResponse(BaseModel):
    summary: str = Field(..., max_length=4000)
    confidence: str
    fallback_used: bool = False
    safety_notes: Optional[str] = None

    @field_validator("summary")
    @classmethod
    def summary_not_empty(cls, value: str) -> str:
        clean = value.strip()
        if not clean:
            raise ValueError("Summary cannot be empty")
        return clean

    @field_validator("confidence")
    @classmethod
    def confidence_valid(cls, value: str) -> str:
        clean = value.strip().lower()
        if clean not in {"high", "medium", "low"}:
            raise ValueError("confidence must be high, medium, or low")
        return clean


class NoteActionExtractionItem(BaseModel):
    item_type: str
    title: str = Field(..., max_length=160)
    due_date: Optional[datetime] = None
    reminder_time: Optional[datetime] = None
    confidence: str
    reason: str = Field(..., max_length=240)
    requires_confirmation: bool = True

    @field_validator("item_type")
    @classmethod
    def item_type_valid(cls, value: str) -> str:
        clean = value.strip().lower()
        if clean not in ALLOWED_NOTE_ACTION_ITEM_TYPES:
            raise ValueError("Unsupported action item type")
        return clean

    @field_validator("title")
    @classmethod
    def action_title_valid(cls, value: str) -> str:
        clean = value.strip()
        if not clean:
            raise ValueError("Action title cannot be empty")
        return clean

    @field_validator("confidence")
    @classmethod
    def action_confidence_valid(cls, value: str) -> str:
        clean = value.strip().lower()
        if clean not in {"high", "medium", "low"}:
            raise ValueError("confidence must be high, medium, or low")
        return clean

    @field_validator("reason")
    @classmethod
    def reason_valid(cls, value: str) -> str:
        clean = value.strip()
        if not clean:
            raise ValueError("Reason cannot be empty")
        return clean

    @field_validator("requires_confirmation")
    @classmethod
    def confirmation_required(cls, value: bool) -> bool:
        if value is not True:
            raise ValueError("Smart note action items require confirmation")
        return value


class NoteActionExtractionResponse(BaseModel):
    extracted_items: list[NoteActionExtractionItem]
    requires_confirmation: bool = True
    fallback_used: bool = False
    safety_notes: Optional[str] = None

    @field_validator("requires_confirmation")
    @classmethod
    def response_confirmation_required(cls, value: bool) -> bool:
        if value is not True:
            raise ValueError("Smart note action extraction requires confirmation")
        return value


class SmartNoteJobCreate(BaseModel):
    note_id: uuid.UUID
    job_type: str
    input_attachment_id: Optional[uuid.UUID] = None

    @field_validator("job_type")
    @classmethod
    def job_type_valid(cls, value: str) -> str:
        clean = value.strip().lower()
        if clean not in ALLOWED_SMART_NOTE_JOB_TYPES:
            raise ValueError("Unsupported smart note job type")
        return clean


class SmartNoteJobUpdate(BaseModel):
    status: Optional[str] = None
    result_text: Optional[str] = Field(default=None, max_length=20000)
    result_json: Optional[dict | list] = None
    error_code: Optional[str] = Field(default=None, max_length=80)
    completed_at: Optional[datetime] = None

    @field_validator("status")
    @classmethod
    def status_valid(cls, value: str | None) -> str | None:
        if value is None:
            return None
        clean = value.strip().lower()
        if clean not in ALLOWED_SMART_NOTE_JOB_STATUSES:
            raise ValueError("Unsupported smart note job status")
        return clean

    @field_validator("error_code")
    @classmethod
    def error_code_valid(cls, value: str | None) -> str | None:
        if value is None:
            return None
        clean = value.strip().lower()
        return clean or None


class SmartNoteJobResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    note_id: uuid.UUID
    job_type: str
    status: str
    input_attachment_id: Optional[uuid.UUID]
    result_text: Optional[str]
    result_json: Optional[dict | list]
    error_code: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]

    model_config = {"from_attributes": True}
