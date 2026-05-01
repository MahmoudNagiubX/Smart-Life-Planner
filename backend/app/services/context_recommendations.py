from __future__ import annotations


VALID_TIME_BLOCKS = {"morning", "afternoon", "evening", "night"}


def build_time_context_recommendations(
    *,
    local_time_block: str,
    energy_level: str | None,
    goals: list[str] | None,
) -> list[dict]:
    block = local_time_block if local_time_block in VALID_TIME_BLOCKS else "morning"
    normalized_goals = {goal.strip().lower() for goal in (goals or [])}
    energy = energy_level or "medium"
    recommendations = [_base_recommendation(block, energy)]

    goal_recommendation = _goal_recommendation(block, normalized_goals, energy)
    if goal_recommendation:
        recommendations.append(goal_recommendation)

    recommendations.append(_supporting_recommendation(block))
    return recommendations


def _base_recommendation(block: str, energy: str) -> dict:
    if block == "morning":
        return {
            "task_type": "deep_work_study",
            "title": "Deep work or study",
            "reason": "Morning is usually best for high-focus work.",
            "suggested_energy": "high" if energy == "high" else "medium",
            "preference_match": False,
        }
    if block == "afternoon":
        return {
            "task_type": "medium_task",
            "title": "Medium-effort tasks",
            "reason": "Afternoon is a practical window for steady execution.",
            "suggested_energy": "medium",
            "preference_match": False,
        }
    if block == "evening":
        return {
            "task_type": "review_planning",
            "title": "Review and planning",
            "reason": "Evening works well for reflection, planning, and light cleanup.",
            "suggested_energy": "low",
            "preference_match": False,
        }
    return {
        "task_type": "shutdown_low_load",
        "title": "Shutdown or low-load work",
        "reason": "Night recommendations avoid heavy cognitive load.",
        "suggested_energy": "low",
        "preference_match": False,
    }


def _goal_recommendation(block: str, goals: set[str], energy: str) -> dict | None:
    if "study" in goals:
        return {
            "task_type": "study_session" if block in {"morning", "afternoon"} else "review",
            "title": "Study goal block",
            "reason": "Your study goal is prioritized for this time window.",
            "suggested_energy": "high" if block == "morning" and energy == "high" else "medium",
            "preference_match": True,
        }
    if "work" in goals:
        return {
            "task_type": "work_execution" if block != "night" else "work_shutdown",
            "title": "Work goal block",
            "reason": "Your work goal is matched to the current time context.",
            "suggested_energy": "medium",
            "preference_match": True,
        }
    if "spiritual growth" in goals:
        return {
            "task_type": "spiritual_reflection",
            "title": "Spiritual reflection",
            "reason": "Your spiritual growth goal fits a calm, intentional block.",
            "suggested_energy": "low",
            "preference_match": True,
        }
    if "fitness" in goals:
        return {
            "task_type": "movement_hydration",
            "title": "Movement or hydration",
            "reason": "Your fitness goal can be supported with a small physical action.",
            "suggested_energy": "medium" if block in {"morning", "afternoon"} else "low",
            "preference_match": True,
        }
    if "self improvement" in goals:
        return {
            "task_type": "reading_reflection",
            "title": "Reading or reflection",
            "reason": "Your self-improvement goal fits a focused but manageable task.",
            "suggested_energy": "medium",
            "preference_match": True,
        }
    return None


def _supporting_recommendation(block: str) -> dict:
    if block == "morning":
        return {
            "task_type": "plan_top_tasks",
            "title": "Pick top tasks",
            "reason": "A short plan makes the morning focus block easier to protect.",
            "suggested_energy": "low",
            "preference_match": False,
        }
    if block == "afternoon":
        return {
            "task_type": "admin_cleanup",
            "title": "Admin cleanup",
            "reason": "Afternoon is suitable for medium-friction cleanup work.",
            "suggested_energy": "medium",
            "preference_match": False,
        }
    if block == "evening":
        return {
            "task_type": "light_review",
            "title": "Light review",
            "reason": "A light review can close loops without adding pressure.",
            "suggested_energy": "low",
            "preference_match": False,
        }
    return {
        "task_type": "shutdown_routine",
        "title": "Shutdown routine",
        "reason": "A simple shutdown helps tomorrow start cleanly.",
        "suggested_energy": "low",
        "preference_match": False,
    }
