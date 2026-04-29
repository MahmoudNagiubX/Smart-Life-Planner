import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field


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


class QuranGoalUpsert(BaseModel):
    daily_page_target: int = Field(ge=1, le=604)


class QuranProgressUpdate(BaseModel):
    pages_completed: int = Field(ge=0, le=604)


class QuranGoalResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    daily_page_target: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class QuranProgressResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    progress_date: date
    pages_completed: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class QuranWeeklyProgressItem(BaseModel):
    progress_date: date
    pages_completed: int
    target_met: bool


class QuranGoalSummaryResponse(BaseModel):
    goal: Optional[QuranGoalResponse]
    today: Optional[QuranProgressResponse]
    today_pages_completed: int
    progress_percent: int
    weekly_total_pages: int
    weekly_target_pages: int
    weekly_summary: list[QuranWeeklyProgressItem]


class RamadanFastingLogUpdate(BaseModel):
    fasted: bool
    note: Optional[str] = Field(default=None, max_length=500)


class RamadanFastingLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    fasting_date: date
    fasted: bool
    note: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class RamadanDailySummaryResponse(BaseModel):
    date: date
    today: Optional[RamadanFastingLogResponse]
    month: int
    year: int
    month_fasted_count: int
    month_not_fasted_count: int
    month_logged_count: int
