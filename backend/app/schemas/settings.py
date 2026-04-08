from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime


class SettingsResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    timezone: str
    language: str
    prayer_calculation_method: str
    prayer_location_lat: Optional[float]
    prayer_location_lng: Optional[float]
    theme: str
    notifications_enabled: bool
    updated_at: datetime

    model_config = {"from_attributes": True}


class SettingsUpdate(BaseModel):
    timezone: Optional[str] = None
    language: Optional[str] = None
    prayer_calculation_method: Optional[str] = None
    prayer_location_lat: Optional[float] = None
    prayer_location_lng: Optional[float] = None
    theme: Optional[str] = None
    notifications_enabled: Optional[bool] = None