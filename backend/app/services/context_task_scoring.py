from __future__ import annotations

from datetime import datetime, timezone


PRIORITY_WEIGHT = 35
TIME_MATCH_WEIGHT = 25
ENERGY_MATCH_WEIGHT = 20
LOCATION_MATCH_WEIGHT = 10
WEATHER_MATCH_WEIGHT = 10
FRICTION_WEIGHT = 15


def score_context_task(
    task,
    *,
    local_time_block: str,
    energy_level: str,
    location_context: str | None = None,
    weather_summary: str | None = None,
    now: datetime | None = None,
) -> dict:
    """Algorithm: Weighted Scoring
    Used for: Context-aware task ranking.
    Complexity: O(1) per task.
    Notes: Adds positive context components and subtracts friction penalties.
    """
    priority_score = _priority_score(getattr(task, "priority", "medium"))
    time_match_score = _time_match_score(local_time_block, task)
    energy_match_score = _energy_match_score(
        energy_level,
        getattr(task, "energy_required", "medium"),
    )
    location_match_score = _location_match_score(location_context, task)
    weather_match_score = _weather_match_score(weather_summary, task)
    task_friction = _task_friction(task, energy_level)

    score = (
        PRIORITY_WEIGHT * priority_score
        + TIME_MATCH_WEIGHT * time_match_score
        + ENERGY_MATCH_WEIGHT * energy_match_score
        + LOCATION_MATCH_WEIGHT * location_match_score
        + WEATHER_MATCH_WEIGHT * weather_match_score
        - FRICTION_WEIGHT * task_friction
    )
    due_bonus = _due_bonus(getattr(task, "due_at", None), now)
    final_score = max(0, min(100, round(score + due_bonus, 2)))

    return {
        "score": final_score,
        "priority_component": round(PRIORITY_WEIGHT * priority_score, 2),
        "time_match_component": round(TIME_MATCH_WEIGHT * time_match_score, 2),
        "energy_match_component": round(ENERGY_MATCH_WEIGHT * energy_match_score, 2),
        "location_match_component": round(
            LOCATION_MATCH_WEIGHT * location_match_score,
            2,
        ),
        "weather_match_component": round(
            WEATHER_MATCH_WEIGHT * weather_match_score,
            2,
        ),
        "friction_penalty": round(FRICTION_WEIGHT * task_friction, 2),
        "due_bonus": due_bonus,
        "explanation": _score_explanation(
            local_time_block,
            energy_level,
            getattr(task, "energy_required", "medium"),
            task_friction,
        ),
    }


def rank_context_tasks(
    tasks: list,
    *,
    local_time_block: str,
    energy_level: str,
    location_context: str | None = None,
    weather_summary: str | None = None,
    limit: int = 5,
) -> list[tuple[object, dict]]:
    """Algorithm: Ranking by Weighted Score
    Used for: Context intelligence recommendations.
    Complexity: O(n log n) because scored tasks are sorted.
    Notes: Returns the highest-scoring incomplete tasks up to the limit.
    """
    scored = [
        (
            task,
            score_context_task(
                task,
                local_time_block=local_time_block,
                energy_level=energy_level,
                location_context=location_context,
                weather_summary=weather_summary,
            ),
        )
        for task in tasks
        if getattr(task, "status", None) != "completed"
    ]
    return sorted(scored, key=lambda item: item[1]["score"], reverse=True)[:limit]


def _priority_score(priority: str) -> float:
    return {"high": 1.0, "medium": 0.65, "low": 0.35}.get(priority, 0.65)


def _time_match_score(block: str, task) -> float:
    category = _task_text(task)
    energy = getattr(task, "energy_required", "medium")
    difficulty = getattr(task, "difficulty_level", "medium")
    if block == "morning":
        if energy == "high" or difficulty == "hard":
            return 1.0
        if any(term in category for term in {"study", "deep", "work", "focus"}):
            return 0.9
        return 0.6
    if block == "afternoon":
        if energy == "medium":
            return 1.0
        return 0.75 if energy == "low" else 0.65
    if block == "evening":
        if any(term in category for term in {"review", "plan", "reading", "reflect"}):
            return 1.0
        return 0.85 if energy in {"low", "medium"} else 0.45
    if any(term in category for term in {"shutdown", "review", "plan", "reading"}):
        return 1.0
    return 0.9 if energy == "low" else 0.25


def _energy_match_score(current_energy: str, required_energy: str) -> float:
    matrix = {
        "low": {"low": 1.0, "medium": 0.45, "high": 0.1},
        "medium": {"low": 0.8, "medium": 1.0, "high": 0.55},
        "high": {"low": 0.6, "medium": 0.85, "high": 1.0},
    }
    return matrix.get(current_energy, matrix["medium"]).get(required_energy, 0.7)


def _location_match_score(location_context: str | None, task) -> float:
    if not location_context:
        return 0.5
    context = location_context.lower()
    text = _task_text(task)
    if any(term in text and term in context for term in ["home", "office", "work", "campus", "gym"]):
        return 1.0
    return 0.55


def _weather_match_score(weather_summary: str | None, task) -> float:
    if not weather_summary:
        return 0.0
    weather = weather_summary.lower()
    text = _task_text(task)
    if any(term in weather for term in {"rain", "storm", "cold"}) and any(
        term in text for term in {"indoor", "study", "reading", "home"}
    ):
        return 1.0
    if "hot" in weather and any(term in text for term in {"hydration", "water", "indoor"}):
        return 1.0
    return 0.4


def _task_friction(task, current_energy: str) -> float:
    difficulty = getattr(task, "difficulty_level", "medium")
    minutes = getattr(task, "estimated_minutes", None) or 30
    required_energy = getattr(task, "energy_required", "medium")
    friction = {"easy": 0.2, "medium": 0.45, "hard": 0.8}.get(difficulty, 0.45)
    if minutes > 90:
        friction += 0.2
    elif minutes <= 15:
        friction -= 0.1
    if current_energy == "low" and required_energy == "high":
        friction += 0.25
    return max(0.0, min(1.0, friction))


def _due_bonus(due_at: datetime | None, now: datetime | None) -> float:
    if due_at is None:
        return 0
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    due = due_at if due_at.tzinfo else due_at.replace(tzinfo=timezone.utc)
    hours = (due - current).total_seconds() / 3600
    if hours < 0:
        return 8
    if hours <= 24:
        return 6
    if hours <= 72:
        return 3
    return 0


def _task_text(task) -> str:
    values = [
        getattr(task, "title", ""),
        getattr(task, "description", "") or "",
        getattr(task, "category", "") or "",
    ]
    return " ".join(values).lower()


def _score_explanation(
    block: str,
    current_energy: str,
    required_energy: str,
    friction: float,
) -> str:
    if current_energy == "low" and required_energy == "high":
        return f"Lower score because this is high-energy work during a {block} low-energy context."
    if friction <= 0.25:
        return f"Good fit for {block}: low friction and {required_energy} energy."
    return f"Ranked for {block} using priority, energy fit, due date, and task friction."
