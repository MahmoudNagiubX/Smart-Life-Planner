from datetime import date, timedelta

import pytest
from pydantic import ValidationError

from app.schemas.ai import GoalRoadmapRequest, GoalRoadmapResponse
from app.services.goal_roadmap import generate_goal_roadmap


def test_goal_roadmap_request_validates_title_and_hours():
    payload = GoalRoadmapRequest(
        goal_title=" Learn ML basics ",
        weekly_available_hours=6,
    )

    assert payload.goal_title == "Learn ML basics"

    with pytest.raises(ValidationError):
        GoalRoadmapRequest(goal_title=" ", weekly_available_hours=6)


def test_goal_roadmap_generator_requires_confirmation():
    result = generate_goal_roadmap(
        goal_title="Learn ML basics",
        deadline=date.today() + timedelta(days=42),
        current_level="beginner",
        weekly_available_hours=5,
        constraints="college schedule",
    )
    response = GoalRoadmapResponse(
        goal_title="Learn ML basics",
        deadline=None,
        milestones=result["milestones"],
        suggested_tasks=result["suggested_tasks"],
        schedule_suggestion=result["schedule_suggestion"],
        confidence=result["confidence"],
        requires_confirmation=result["requires_confirmation"],
        fallback_used=result["fallback_used"],
    )

    assert response.requires_confirmation is True
    assert len(response.milestones) >= 2
    assert response.suggested_tasks[0].title
