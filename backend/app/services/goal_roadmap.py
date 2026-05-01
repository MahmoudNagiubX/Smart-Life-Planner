from __future__ import annotations

from datetime import date


def generate_goal_roadmap(
    *,
    goal_title: str,
    deadline: date | None,
    current_level: str | None,
    weekly_available_hours: int,
    constraints: str | None,
) -> dict:
    weeks = _estimate_weeks(deadline)
    weekly_hours = max(1, min(weekly_available_hours, 40))
    level = (current_level or "beginner").strip().lower()
    milestone_count = 4 if weeks >= 4 else max(2, weeks)
    milestones = []
    tasks = []

    phases = _phase_names(level, milestone_count)
    for index, phase in enumerate(phases, start=1):
        week = min(index, weeks)
        milestones.append(
            {
                "index": index,
                "title": phase,
                "description": f"Build progress toward {goal_title} with a focused {phase.lower()} phase.",
                "target_week": week,
            }
        )
        tasks.extend(
            [
                {
                    "milestone_index": index,
                    "title": f"{phase}: plan next actions",
                    "description": _task_description(goal_title, constraints),
                    "priority": "high" if index == 1 else "medium",
                    "estimated_minutes": min(120, max(30, weekly_hours * 30)),
                    "suggested_week": week,
                },
                {
                    "milestone_index": index,
                    "title": f"{phase}: complete practice block",
                    "description": f"Complete one practical block for {goal_title}.",
                    "priority": "medium",
                    "estimated_minutes": min(180, max(45, weekly_hours * 40)),
                    "suggested_week": week,
                },
            ]
        )

    return {
        "milestones": milestones,
        "suggested_tasks": tasks,
        "schedule_suggestion": (
            f"Use {weekly_hours} hour(s) per week across {weeks} week(s). "
            "Keep one review block at the end of each week."
        ),
        "confidence": "medium" if constraints else "high",
        "requires_confirmation": True,
        "fallback_used": True,
    }


def _estimate_weeks(deadline: date | None) -> int:
    if deadline is None:
        return 6
    remaining_days = max(7, (deadline - date.today()).days)
    return max(1, min(26, (remaining_days + 6) // 7))


def _phase_names(level: str, milestone_count: int) -> list[str]:
    if level in {"advanced", "expert"}:
        base = ["Audit gaps", "Build advanced practice", "Ship proof", "Review and refine"]
    elif level in {"intermediate"}:
        base = ["Refresh foundations", "Practice consistently", "Apply in project", "Review progress"]
    else:
        base = ["Learn foundations", "Practice basics", "Build small project", "Review and repeat"]
    return base[:milestone_count]


def _task_description(goal_title: str, constraints: str | None) -> str:
    if constraints:
        return f"Plan around constraint: {constraints[:160]}"
    return f"Define the next concrete actions for {goal_title}."
