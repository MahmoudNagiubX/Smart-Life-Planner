from datetime import date, datetime, timezone
from adhanpy.calculation import CalculationMethod
from adhanpy.prayer import PrayerTimes
from adhanpy.astronomy import Coordinates

PRAYER_NAMES = ["fajr", "dhuhr", "asr", "maghrib", "isha"]

METHOD_MAP = {
    "MWL": CalculationMethod.muslim_world_league,
    "ISNA": CalculationMethod.north_america,
    "Egypt": CalculationMethod.egyptian,
    "Makkah": CalculationMethod.umm_al_qura,
    "Karachi": CalculationMethod.karachi,
    "Tehran": CalculationMethod.tehran,
    "Gulf": CalculationMethod.gulf,
}


def calculate_prayer_times(
    lat: float,
    lng: float,
    prayer_date: date,
    method: str = "MWL",
) -> dict[str, datetime]:
    coordinates = Coordinates(lat, lng)
    calc_method = METHOD_MAP.get(method, CalculationMethod.muslim_world_league)
    params = calc_method()

    times = PrayerTimes(coordinates, prayer_date, params)

    return {
        "fajr": times.fajr,
        "dhuhr": times.dhuhr,
        "asr": times.asr,
        "maghrib": times.maghrib,
        "isha": times.isha,
    }