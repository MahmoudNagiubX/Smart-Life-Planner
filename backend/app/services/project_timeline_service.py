from datetime import datetime, timedelta, timezone
from typing import Iterable

from app.schemas.task import (
    ProjectTimelineDependencyResponse,
    ProjectTimelineResponse,
    ProjectTimelineTaskBarResponse,
)


class TimelineDateValidationError(ValueError):
    pass


def build_project_timeline(project, tasks: Iterable, now: datetime | None = None) -> ProjectTimelineResponse:
    current_time = _aware_utc(now or datetime.now(timezone.utc))
    task_list = list(tasks)
    task_ids = {task.id for task in task_list}
    task_by_id = {task.id: task for task in task_list}
    dependencies: list[ProjectTimelineDependencyResponse] = []

    for task in task_list:
        for dependency in getattr(task, "dependencies", []) or []:
            if dependency.task_id in task_ids and dependency.depends_on_task_id in task_ids:
                dependencies.append(
                    ProjectTimelineDependencyResponse(
                        task_id=dependency.task_id,
                        depends_on_task_id=dependency.depends_on_task_id,
                        dependency_type=dependency.dependency_type,
                    )
                )

    bars: list[ProjectTimelineTaskBarResponse] = []
    for task in task_list:
        start_date = _timeline_start(task)
        due_date = _aware_utc(getattr(task, "due_at", None))
        dependency_ids = [
            dependency.depends_on_task_id
            for dependency in getattr(task, "dependencies", []) or []
            if dependency.depends_on_task_id in task_ids
        ]
        conflict_reasons = _conflict_reasons(task, task_by_id, start_date, due_date)

        bars.append(
            ProjectTimelineTaskBarResponse(
                task_id=task.id,
                title=task.title,
                status=task.status,
                priority=task.priority,
                project_id=task.project_id,
                start_date=start_date,
                due_date=due_date,
                estimated_duration_minutes=getattr(task, "estimated_minutes", None),
                dependency_ids=dependency_ids,
                overdue=_is_overdue(task, due_date, current_time),
                conflict=bool(conflict_reasons),
                conflict_reasons=conflict_reasons,
            )
        )

    bars.sort(key=_bar_sort_key)
    dependencies.sort(key=lambda item: (str(item.task_id), str(item.depends_on_task_id)))
    return ProjectTimelineResponse(project=project, task_bars=bars, dependencies=dependencies)


def validate_timeline_date_update(task, data: dict) -> None:
    start_date = _aware_utc(data.get("earliest_start_at", getattr(task, "earliest_start_at", None)))
    due_date = _aware_utc(data.get("due_at", getattr(task, "due_at", None)))

    if start_date is not None and due_date is not None and start_date > due_date:
        raise TimelineDateValidationError("Start date cannot be after due date")

    if start_date is not None:
        for dependency in getattr(task, "dependencies", []) or []:
            prerequisite = getattr(dependency, "prerequisite", None)
            prerequisite_due = _aware_utc(getattr(prerequisite, "due_at", None))
            if prerequisite_due is not None and prerequisite_due > start_date:
                raise TimelineDateValidationError(
                    "Task cannot start before a blocking dependency is due"
                )

    if due_date is not None:
        for dependency in getattr(task, "dependents", []) or []:
            dependent = getattr(dependency, "task", None)
            dependent_start = _timeline_start(dependent) if dependent is not None else None
            if dependent_start is not None and due_date > dependent_start:
                raise TimelineDateValidationError(
                    "Task due date cannot move after a dependent task starts"
                )


def _timeline_start(task) -> datetime | None:
    explicit_start = _aware_utc(getattr(task, "earliest_start_at", None))
    if explicit_start is not None:
        return explicit_start

    due_date = _aware_utc(getattr(task, "due_at", None))
    estimate = getattr(task, "estimated_minutes", None)
    if due_date is not None and estimate is not None and estimate > 0:
        return due_date - timedelta(minutes=estimate)
    return due_date


def _is_overdue(task, due_date: datetime | None, now: datetime) -> bool:
    return due_date is not None and due_date < now and getattr(task, "status", None) != "completed"


def _conflict_reasons(task, task_by_id: dict, start_date: datetime | None, due_date: datetime | None) -> list[str]:
    reasons: list[str] = []
    if start_date is not None and due_date is not None and start_date > due_date:
        reasons.append("start_after_due")

    for dependency in getattr(task, "dependencies", []) or []:
        prerequisite = task_by_id.get(dependency.depends_on_task_id)
        if prerequisite is None or start_date is None:
            continue
        prerequisite_due = _aware_utc(getattr(prerequisite, "due_at", None))
        if prerequisite_due is not None and prerequisite_due > start_date:
            reasons.append("dependency_finishes_after_start")
    return sorted(set(reasons))


def _bar_sort_key(bar: ProjectTimelineTaskBarResponse):
    start = bar.start_date or datetime.max.replace(tzinfo=timezone.utc)
    due = bar.due_date or datetime.max.replace(tzinfo=timezone.utc)
    return (start, due, bar.title.lower())


def _aware_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)
