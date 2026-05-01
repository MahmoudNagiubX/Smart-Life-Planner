from datetime import date

from app.services.islamic_calendar import (
    gregorian_to_hijri,
    upcoming_islamic_events,
)


def test_gregorian_to_hijri_returns_known_ramadan_estimate():
    hijri = gregorian_to_hijri(date(2024, 3, 11))

    assert hijri.year == 1445
    assert hijri.month == 9
    assert hijri.day == 1
    assert hijri.label == "1 Ramadan 1445 AH"


def test_upcoming_islamic_events_include_required_key_events():
    events = upcoming_islamic_events(date(2026, 5, 1), limit=12)
    keys = {event.key for event in events}

    assert "arafah" in keys
    assert "eid_al_adha" in keys
    assert "ashura" in keys
    assert "ramadan_start" in keys
    assert "ramadan_end" in keys
    assert "eid_al_fitr" in keys
    assert all(event.estimated for event in events)
