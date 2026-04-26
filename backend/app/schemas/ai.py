from pydantic import BaseModel, field_validator
from typing import Optional

class ParseTaskRequest(BaseModel):
    input_text: str

    @field_validator("input_text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("input_text cannot be empty")
        return v.strip()

class ParseTaskResponse(BaseModel):
    success: bool
    data: dict
    raw_input: str
    requires_confirmation: bool = True
    parse_status: str = "parsed"
    fallback_reason: Optional[str] = None

class NextActionResponse(BaseModel):
    task_id: Optional[str]
    title: Optional[str]
    reason: str
    confidence: str

class DailyPlanRequest(BaseModel):
    date: Optional[str] = None

class DailyPlanItem(BaseModel):
    task_id: str
    title: str
    suggested_time: str
    duration_minutes: int
    reason: str

class DailyPlanResponse(BaseModel):
    date: str
    plan: list[DailyPlanItem]
