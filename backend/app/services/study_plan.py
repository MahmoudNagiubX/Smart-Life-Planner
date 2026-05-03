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
    practice_target = {"easy": 10, "medium": 15, "hard": 20}.get(
        difficulty.lower(),
        15,
    )
    practice_minutes = min(practice_target, max(5, daily_minutes // 3))
    study_minutes = max(10, daily_minutes - practice_minutes)
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
                "study_minutes": study_minutes,
                "practice_minutes": practice_minutes,
                "revision": is_revision,
                "priority": "high" if is_revision else "medium",
            }
        )

    recommended_daily_minutes = 45 + difficulty_factor * 15
    topic_load = len(clean_topics) * difficulty_factor
    available_blocks = max(1, usable_days * max(1, daily_minutes // 45))
    return {
        "subject": subject,
        "exam_date": exam_date,
        "daily_plan": plan,
        "confidence": "medium",
        "overload_warning": (
            daily_minutes < recommended_daily_minutes or topic_load > available_blocks
        ),
        "requires_confirmation": True,
    }
