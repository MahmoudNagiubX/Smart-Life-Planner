from datetime import date, timedelta

import pytest
from pydantic import ValidationError

from app.schemas.ai import StudyPlanRequest, StudyPlanResponse
from app.services.study_plan import generate_study_plan


def test_study_plan_request_validates_topics_and_minutes():
    payload = StudyPlanRequest(
        subject="Physics",
        exam_date=date.today() + timedelta(days=10),
        topics=[" Mechanics "],
        difficulty="HARD",
        available_daily_study_minutes=90,
    )

    assert payload.topics == ["Mechanics"]
    assert payload.difficulty == "hard"

    with pytest.raises(ValidationError):
        StudyPlanRequest(
            subject="Physics",
            exam_date=date.today(),
            topics=[],
            available_daily_study_minutes=90,
        )


def test_study_plan_requires_confirmation():
    result = generate_study_plan(
        subject="Physics",
        exam_date=date.today() + timedelta(days=7),
        topics=["Mechanics", "Waves"],
        difficulty="medium",
        daily_minutes=90,
    )
    response = StudyPlanResponse(
        subject=result["subject"],
        exam_date=result["exam_date"],
        daily_plan=result["daily_plan"],
        confidence=result["confidence"],
        overload_warning=result["overload_warning"],
        requires_confirmation=True,
    )

    assert response.requires_confirmation is True
    assert len(response.daily_plan) >= 1
    assert response.daily_plan[0].practice_minutes > 0
