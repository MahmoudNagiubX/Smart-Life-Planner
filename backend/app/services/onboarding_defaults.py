import re
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.habit import Habit


def normalize_goal_key(goal: str) -> str:
    normalized = goal.strip().lower()
    normalized = re.sub(r"[\s-]+", "_", normalized)
    normalized = re.sub(r"[^a-z0-9_]", "", normalized)
    return normalized.strip("_")


DEFAULT_HABITS_BY_GOAL: dict[str, list[dict[str, str]]] = {
    "study": [
        {
            "title": "Daily Study Session",
            "description": "Protect one focused study block each day.",
            "category": "study",
        },
    ],
    "work": [
        {
            "title": "Deep Work Block",
            "description": "Complete one distraction-free work block.",
            "category": "work",
        },
    ],
    "self_improvement": [
        {
            "title": "Reading & Reflection",
            "description": "Read, reflect, or capture one useful lesson.",
            "category": "self_improvement",
        },
    ],
    "fitness": [
        {
            "title": "Exercise & Hydration",
            "description": "Move your body and keep hydration visible.",
            "category": "fitness",
        },
    ],
    "spiritual_growth": [
        {
            "title": "Prayer Tracking",
            "description": "Check in with daily prayer consistency.",
            "category": "spiritual_growth",
        },
        {
            "title": "Daily Quran Reading",
            "description": "Read or review a small Quran portion.",
            "category": "spiritual_growth",
        },
    ],
}


def normalize_goal_keys(goals: list[str]) -> list[str]:
    seen: set[str] = set()
    normalized_goals: list[str] = []
    for goal in goals:
        normalized = normalize_goal_key(goal)
        if normalized and normalized not in seen:
            seen.add(normalized)
            normalized_goals.append(normalized)
    return normalized_goals


async def create_default_habits_for_goals(
    db: AsyncSession,
    user_id: uuid.UUID,
    goals: list[str],
) -> list[Habit]:
    defaults = [
        habit
        for goal in normalize_goal_keys(goals)
        for habit in DEFAULT_HABITS_BY_GOAL.get(goal, [])
    ]
    if not defaults:
        return []

    target_titles = {habit["title"] for habit in defaults}
    existing_result = await db.execute(
        select(Habit.title).where(
            Habit.user_id == user_id,
            Habit.is_deleted == False,
            Habit.title.in_(target_titles),
        )
    )
    existing_titles = set(existing_result.scalars().all())

    habits_to_create = [
        Habit(
            user_id=user_id,
            title=habit["title"],
            description=habit["description"],
            category=habit["category"],
            frequency_type="daily",
            is_active=True,
        )
        for habit in defaults
        if habit["title"] not in existing_titles
    ]
    if not habits_to_create:
        return []

    db.add_all(habits_to_create)
    await db.commit()
    for habit in habits_to_create:
        await db.refresh(habit)
    return habits_to_create
