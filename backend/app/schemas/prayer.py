import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel


class PrayerResponse(BaseModel):
    prayer_name: str
    scheduled_at: Optional[datetime]
    completed: bool
    completed_at: Optional[datetime]


class DailyPrayerResponse(BaseModel):
    date: str
    prayers: list[PrayerResponse]
    completed_count: int
    total_count: int


class PrayerLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    prayer_name: str
    prayer_date: date
    scheduled_at: Optional[datetime]
    completed: bool
    completed_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}