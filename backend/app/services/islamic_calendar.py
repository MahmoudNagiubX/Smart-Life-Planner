from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from math import ceil, floor


HIJRI_MONTH_NAMES = {
    1: "Muharram",
    2: "Safar",
    3: "Rabi al-Awwal",
    4: "Rabi al-Thani",
    5: "Jumada al-Awwal",
    6: "Jumada al-Thani",
    7: "Rajab",
    8: "Sha'ban",
    9: "Ramadan",
    10: "Shawwal",
    11: "Dhu al-Qadah",
    12: "Dhu al-Hijjah",
}


@dataclass(frozen=True)
class HijriDate:
    year: int
    month: int
    day: int

    @property
    def month_name(self) -> str:
        return HIJRI_MONTH_NAMES[self.month]

    @property
    def label(self) -> str:
        return f"{self.day} {self.month_name} {self.year} AH"


@dataclass(frozen=True)
class IslamicCalendarEvent:
    key: str
    title: str
    hijri_month: int
    hijri_day: int
    gregorian_date: date
    hijri_label: str
    estimated: bool
    description: str


def gregorian_to_hijri(target_date: date) -> HijriDate:
    """Civil/tabular Hijri estimate. Real observance can vary by moon sighting."""
    jd = _gregorian_to_jdn(target_date.year, target_date.month, target_date.day)
    lunar_days = jd - 1948440 + 10632
    cycle = (lunar_days - 1) // 10631
    lunar_days = lunar_days - 10631 * cycle + 354
    month_adjustment = (
        ((10985 - lunar_days) // 5316) * ((50 * lunar_days) // 17719)
        + (lunar_days // 5670) * ((43 * lunar_days) // 15238)
    )
    lunar_days = (
        lunar_days
        - ((30 - month_adjustment) // 15)
        * ((17719 * month_adjustment) // 50)
        - (month_adjustment // 16) * ((15238 * month_adjustment) // 43)
        + 29
    )
    month = (24 * lunar_days) // 709
    day = lunar_days - (709 * month) // 24
    year = 30 * cycle + month_adjustment - 30
    return HijriDate(year=year, month=month, day=day)


def islamic_to_gregorian(year: int, month: int, day: int) -> date:
    jdn = (
        day
        + ceil(29.5 * (month - 1))
        + (year - 1) * 354
        + floor((3 + 11 * year) / 30)
        + 1948440
        - 1
    )
    return _jdn_to_gregorian(jdn)


def upcoming_islamic_events(
    target_date: date,
    limit: int = 8,
) -> list[IslamicCalendarEvent]:
    hijri = gregorian_to_hijri(target_date)
    events: list[IslamicCalendarEvent] = []

    for year in range(hijri.year, hijri.year + 3):
        eid_al_fitr = islamic_to_gregorian(year, 10, 1)
        event_specs = [
            (
                "ashura",
                "Ashura",
                1,
                10,
                islamic_to_gregorian(year, 1, 10),
                "10 Muharram",
            ),
            (
                "ramadan_start",
                "Ramadan start",
                9,
                1,
                islamic_to_gregorian(year, 9, 1),
                "1 Ramadan",
            ),
            (
                "ramadan_end",
                "Ramadan end",
                9,
                29,
                eid_al_fitr - timedelta(days=1),
                "29 Ramadan",
            ),
            (
                "eid_al_fitr",
                "Eid al-Fitr",
                10,
                1,
                eid_al_fitr,
                "1 Shawwal",
            ),
            (
                "arafah",
                "Day of Arafah",
                12,
                9,
                islamic_to_gregorian(year, 12, 9),
                "9 Dhu al-Hijjah",
            ),
            (
                "eid_al_adha",
                "Eid al-Adha",
                12,
                10,
                islamic_to_gregorian(year, 12, 10),
                "10 Dhu al-Hijjah",
            ),
        ]
        for key, title, month, day, gregorian, hijri_label in event_specs:
            if gregorian >= target_date:
                events.append(
                    IslamicCalendarEvent(
                        key=key,
                        title=title,
                        hijri_month=month,
                        hijri_day=day,
                        gregorian_date=gregorian,
                        hijri_label=f"{hijri_label} {year} AH",
                        estimated=True,
                        description="Estimated by a civil Hijri calculation.",
                    )
                )

    return sorted(events, key=lambda item: item.gregorian_date)[:limit]


def _gregorian_to_jdn(year: int, month: int, day: int) -> int:
    adjustment = (14 - month) // 12
    adjusted_year = year + 4800 - adjustment
    adjusted_month = month + 12 * adjustment - 3
    return (
        day
        + ((153 * adjusted_month + 2) // 5)
        + 365 * adjusted_year
        + adjusted_year // 4
        - adjusted_year // 100
        + adjusted_year // 400
        - 32045
    )


def _jdn_to_gregorian(jdn: int) -> date:
    alpha = jdn + 32044
    beta = (4 * alpha + 3) // 146097
    gamma = alpha - (146097 * beta) // 4
    delta = (4 * gamma + 3) // 1461
    epsilon = gamma - (1461 * delta) // 4
    month_index = (5 * epsilon + 2) // 153
    day = epsilon - (153 * month_index + 2) // 5 + 1
    month = month_index + 3 - 12 * (month_index // 10)
    year = 100 * beta + delta - 4800 + (month_index // 10)
    return date(year, month, day)
