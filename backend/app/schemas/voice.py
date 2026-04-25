from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Literal


class VoiceTranscriptionResponse(BaseModel):
    transcribed_text: str
    language: Optional[str] = "auto"
    duration_seconds: Optional[float] = None
    provider: str


class ParsedVoiceSubtask(BaseModel):
    title: str
    completed: bool = False


class ParsedVoiceTask(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[str] = None
    due_time: Optional[str] = None
    priority: Literal["low", "medium", "high"] = "medium"
    estimated_duration_minutes: Optional[int] = None
    project: Optional[str] = None
    category: Optional[str] = None
    subtasks: List[ParsedVoiceSubtask] = []


class VoiceTaskParseRequest(BaseModel):
    transcribed_text: str
    language: Optional[str] = "auto"

    @field_validator("transcribed_text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("transcribed_text cannot be empty")
        return v.strip()


class VoiceTaskParseResponse(BaseModel):
    detected_intent: str
    confidence: Literal["low", "medium", "high"]
    tasks: List[ParsedVoiceTask]
    confirmation_required: bool = True
    display_text: str


class VoiceTranscribeAndParseResponse(BaseModel):
    transcribed_text: str
    language: Optional[str] = "auto"
    provider: str
    detected_intent: str
    confidence: Literal["low", "medium", "high"]
    tasks: List[ParsedVoiceTask]
    confirmation_required: bool = True
    display_text: str


class BulkTaskItem(BaseModel):
    title: str
    description: Optional[str] = None
    due_at: Optional[str] = None
    priority: Literal["low", "medium", "high"] = "medium"
    estimated_minutes: Optional[int] = None
    project_id: Optional[str] = None
    category: Optional[str] = None
    subtasks: List[ParsedVoiceSubtask] = []


class BulkTaskCreateRequest(BaseModel):
    tasks: List[BulkTaskItem]

    @field_validator("tasks")
    @classmethod
    def tasks_not_empty(cls, v: list) -> list:
        if not v:
            raise ValueError("tasks list cannot be empty")
        if len(v) > 20:
            raise ValueError("Cannot create more than 20 tasks at once")
        return v

class BulkTaskCreateResponse(BaseModel):
    created_count: int
    tasks: List[dict]


class VoiceNoteOrganizeResponse(BaseModel):
    transcribed_text: str
    language: Optional[str] = "auto"
    provider: str
    title: Optional[str] = None
    content: str
    note_type: Literal["text", "checklist", "reflection"] = "text"
    tags: List[str] = Field(default_factory=list)
    confidence: Literal["low", "medium", "high"] = "low"
