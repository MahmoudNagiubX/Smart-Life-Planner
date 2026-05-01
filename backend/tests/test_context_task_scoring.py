from dataclasses import dataclass

from app.services.context_task_scoring import rank_context_tasks, score_context_task


@dataclass
class FakeTask:
    title: str
    priority: str = "medium"
    status: str = "pending"
    category: str | None = None
    energy_required: str = "medium"
    difficulty_level: str = "medium"
    estimated_minutes: int | None = 30
    due_at = None


def test_low_energy_context_prefers_light_task_over_hard_task():
    light = FakeTask(
        title="Review notes",
        priority="medium",
        category="review",
        energy_required="low",
        difficulty_level="easy",
        estimated_minutes=15,
    )
    hard = FakeTask(
        title="Hard project deep work",
        priority="high",
        category="deep work",
        energy_required="high",
        difficulty_level="hard",
        estimated_minutes=120,
    )

    ranked = rank_context_tasks(
        [hard, light],
        local_time_block="evening",
        energy_level="low",
    )

    assert ranked[0][0] == light
    assert ranked[0][1]["score"] > ranked[1][1]["score"]


def test_context_score_returns_explanation_metadata():
    task = FakeTask(title="Study physics", priority="high", energy_required="high")

    scoring = score_context_task(
        task,
        local_time_block="morning",
        energy_level="high",
    )

    assert scoring["score"] > 0
    assert scoring["priority_component"] > 0
    assert "explanation" in scoring
