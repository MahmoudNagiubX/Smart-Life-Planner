from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def classify_local_time_block(local_dt: datetime) -> str:
    hour = local_dt.hour
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 17:
        return "afternoon"
    if 17 <= hour < 21:
        return "evening"
    return "night"


def safe_zone(timezone_name: str | None) -> ZoneInfo:
    try:
        return ZoneInfo(timezone_name or "UTC")
    except ZoneInfoNotFoundError:
        return ZoneInfo("UTC")


def safe_timezone_name(timezone_name: str | None) -> str:
    try:
        ZoneInfo(timezone_name or "UTC")
        return timezone_name or "UTC"
    except ZoneInfoNotFoundError:
        return "UTC"


def local_now(timezone_name: str | None, now: datetime | None = None) -> datetime:
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    return current.astimezone(safe_zone(timezone_name))
