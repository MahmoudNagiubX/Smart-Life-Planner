import uuid
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from pydantic import ValidationError

from app.schemas.task import TaskCreate, TaskUpdate
from app.services.project_timeline_service import build_project_timeline


def test_task_schema_accepts_timeline_alias_fields():
    start = datetime(2026, 5, 1, 9, tzinfo=timezone.utc)
    due = datetime(2026, 5, 1, 11, tzinfo=timezone.utc)

    create = TaskCreate(
        title="Draft project plan",
        start_date=start,
        due_at=due,
        estimated_duration_minutes=90,
    )
    update = TaskUpdate(start_date=start, estimated_duration_minutes=45)

    assert create.start_date == start
    assert create.estimated_minutes == 90
    assert update.estimated_minutes == 45


def test_task_schema_rejects_start_after_due():
    with pytest.raises(ValidationError):
        TaskCreate(
            title="Impossible schedule",
            start_date=datetime(2026, 5, 1, 12, tzinfo=timezone.utc),
            due_at=datetime(2026, 5, 1, 10, tzinfo=timezone.utc),
        )


def test_project_timeline_marks_overdue_and_dependency_conflicts():
    project_id = uuid.uuid4()
    user_id = uuid.uuid4()
    prerequisite_id = uuid.uuid4()
    blocked_id = uuid.uuid4()
    now = datetime(2026, 5, 2, 12, tzinfo=timezone.utc)

    project = SimpleNamespace(
        id=project_id,
        user_id=user_id,
        title="Capstone",
        description=None,
        color_code="#6C63FF",
        status="active",
        created_at=now,
        updated_at=now,
    )
    prerequisite = SimpleNamespace(
        id=prerequisite_id,
        project_id=project_id,
        title="Finish research",
        status="pending",
        priority="high",
        earliest_start_at=now - timedelta(days=2),
        due_at=now - timedelta(hours=1),
        estimated_minutes=120,
        dependencies=[],
    )
    blocked = SimpleNamespace(
        id=blocked_id,
        project_id=project_id,
        title="Write report",
        status="pending",
        priority="medium",
        earliest_start_at=now - timedelta(hours=2),
        due_at=now + timedelta(days=1),
        estimated_minutes=180,
        dependencies=[
            SimpleNamespace(
                task_id=blocked_id,
                depends_on_task_id=prerequisite_id,
                dependency_type="finish_to_start",
            )
        ],
    )

    timeline = build_project_timeline(project, [prerequisite, blocked], now=now)
    bars_by_id = {bar.task_id: bar for bar in timeline.task_bars}

    assert timeline.project.id == project_id
    assert bars_by_id[prerequisite_id].overdue is True
    assert bars_by_id[blocked_id].conflict is True
    assert bars_by_id[blocked_id].dependency_ids == [prerequisite_id]
    assert timeline.dependencies[0].depends_on_task_id == prerequisite_id
