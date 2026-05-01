import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field, computed_field, field_validator


# ── Prayer status values ────────────────────────────────────────────────────
VALID_PRAYER_STATUSES = {"prayed_on_time", "prayed_late", "missed", "excused"}


class PrayerResponse(BaseModel):
    prayer_name: str
    scheduled_at: Optional[datetime]
    completed: bool
    completed_at: Optional[datetime]
    status: Optional[str] = None


class DailyPrayerResponse(BaseModel):
    date: str
    prayers: list[PrayerResponse]
    completed_count: int
    total_count: int
    missed_count: int = 0


class PrayerLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    prayer_name: str
    prayer_date: date
    scheduled_at: Optional[datetime]
    completed: bool
    completed_at: Optional[datetime]
    status: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class PrayerStatusUpdate(BaseModel):
    status: str = Field(
        ...,
        description="One of: prayed_on_time, prayed_late, missed, excused",
    )


# ── Weekly missed-prayer summary ────────────────────────────────────────────
class PrayerDaySummary(BaseModel):
    prayer_date: date
    total: int
    completed: int
    missed: int
    late: int
    excused: int


class PrayerWeeklySummaryResponse(BaseModel):
    week_start: date
    week_end: date
    total_missed: int
    total_completed: int
    total_prayers: int
    today_missed: int
    days: list[PrayerDaySummary]


# ── Quran schemas ────────────────────────────────────────────────────────────
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
    target_pages: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @computed_field
    @property
    def pages_read(self) -> int:
        return self.pages_completed


class QuranWeeklyProgressItem(BaseModel):
    progress_date: date
    pages_completed: int
    target_pages: int
    target_met: bool
    completion_percent: int

    @computed_field
    @property
    def pages_read(self) -> int:
        return self.pages_completed


class QuranGoalSummaryResponse(BaseModel):
    goal: Optional[QuranGoalResponse]
    today: Optional[QuranProgressResponse]
    today_pages_completed: int
    progress_percent: int
    weekly_total_pages: int
    weekly_target_pages: int
    weekly_completion_percent: int
    current_streak_days: int
    weekly_summary: list[QuranWeeklyProgressItem]


# ── Ramadan schemas ──────────────────────────────────────────────────────────
class RamadanFastingLogUpdate(BaseModel):
    fasted: bool
    fast_type: str = "ramadan"
    makeup_for_date: Optional[date] = None
    note: Optional[str] = Field(default=None, max_length=500)

    @field_validator("fast_type")
    @classmethod
    def fast_type_valid(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in {"ramadan", "voluntary", "makeup"}:
            raise ValueError("Unsupported fast_type")
        return normalized


class RamadanFastingLogResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    fasting_date: date
    fasted: bool
    fast_type: str
    makeup_for_date: Optional[date]
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


# Islamic calendar schemas
class HijriDateResponse(BaseModel):
    year: int
    month: int
    day: int
    month_name: str
    label: str
    estimated: bool = True


class IslamicCalendarEventResponse(BaseModel):
    key: str
    title: str
    hijri_month: int
    hijri_day: int
    gregorian_date: date
    hijri_label: str
    estimated: bool
    description: str


class IslamicCalendarResponse(BaseModel):
    gregorian_date: date
    hijri_date: HijriDateResponse
    events: list[IslamicCalendarEventResponse]
    calculation_note: str
