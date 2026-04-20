from datetime import date, datetime, timezone
from adhanpy.calculation import CalculationMethod
from adhanpy.PrayerTimes import PrayerTimes

PRAYER_NAMES = ["fajr", "dhuhr", "asr", "maghrib", "isha"]

METHOD_MAP = {
    "MWL": CalculationMethod.MUSLIM_WORLD_LEAGUE,
    "ISNA": CalculationMethod.NORTH_AMERICA,
    "Egypt": CalculationMethod.EGYPTIAN,
    "Makkah": CalculationMethod.UMM_AL_QURA,
    "Karachi": CalculationMethod.KARACHI,
    "Gulf": CalculationMethod.DUBAI,
}


def calculate_prayer_times(
    lat: float,
    lng: float,
    prayer_date: date,
    method: str = "MWL",
) -> dict[str, datetime]:
    calc_method = METHOD_MAP.get(method, CalculationMethod.MUSLIM_WORLD_LEAGUE)

    times = PrayerTimes(
        (lat, lng),
        datetime.combine(prayer_date, datetime.min.time(), tzinfo=timezone.utc),
        calc_method,
    )

    return {
        "fajr": times.fajr,
        "dhuhr": times.dhuhr,
        "asr": times.asr,
        "maghrib": times.maghrib,
        "isha": times.isha,
    }
