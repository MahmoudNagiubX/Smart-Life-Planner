from __future__ import annotations

from datetime import date, timedelta


def generate_study_plan(
    *,
    subject: str,
    exam_date: date,
    topics: list[str],
    difficulty: str,
    daily_minutes: int,
) -> dict:
    today = date.today()
    days_available = max(1, (exam_date - today).days)
    usable_days = min(days_available, 21)
    clean_topics = [topic.strip() for topic in topics if topic.strip()] or [subject]
    difficulty_factor = {"easy": 1, "medium": 2, "hard": 3}.get(
        difficulty.lower(),
        2,
    )
    plan = []
    for offset in range(usable_days):
        topic = clean_topics[offset % len(clean_topics)]
        study_date = today + timedelta(days=offset)
        is_revision = offset >= max(1, usable_days - 3)
        plan.append(
            {
                "date": study_date,
                "topic": topic,
                "title": (
                    f"Revise {topic}" if is_revision else f"Study {topic}"
                ),
                "study_minutes": max(20, daily_minutes - 15),
                "practice_minutes": 15 + difficulty_factor * 5,
                "revision": is_revision,
                "priority": "high" if is_revision else "medium",
            }
        )

    total_minutes = sum(item["study_minutes"] + item["practice_minutes"] for item in plan)
    available_minutes = usable_days * daily_minutes
    return {
        "subject": subject,
        "exam_date": exam_date,
        "daily_plan": plan,
        "confidence": "medium",
        "overload_warning": total_minutes > available_minutes,
        "requires_confirmation": True,
    }
