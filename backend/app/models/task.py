import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, Integer, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class TaskProject(Base):
    __tablename__ = "task_projects"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    color_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="active", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="project")


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    project_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("task_projects.id", ondelete="SET NULL"), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_type: Mapped[str] = mapped_column(String(30), default="manual", nullable=False)
    priority: Mapped[str] = mapped_column(String(20), default="medium", nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="pending", nullable=False)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    reminder_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    recurrence_rule: Mapped[str | None] = mapped_column(Text, nullable=True)
    estimated_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    estimated_pomodoros: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    completed_pomodoros: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    category: Mapped[str | None] = mapped_column(String(80), nullable=True)
    manual_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    ai_parsed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # H-ASAE execution metadata
    difficulty_level: Mapped[str] = mapped_column(String(20), default="medium", nullable=False)
    energy_required: Mapped[str] = mapped_column(String(20), default="medium", nullable=False)
    is_splittable: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_strict_time: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    earliest_start_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    latest_finish_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    auto_schedule_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    schedule_flexibility: Mapped[str] = mapped_column(String(20), default="flexible", nullable=False)

    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    project: Mapped["TaskProject | None"] = relationship("TaskProject", back_populates="tasks")
    subtasks: Mapped[list["TaskSubtask"]] = relationship("TaskSubtask", back_populates="task", cascade="all, delete-orphan")
    dependencies: Mapped[list["TaskDependency"]] = relationship("TaskDependency", foreign_keys="TaskDependency.task_id", back_populates="task", cascade="all, delete-orphan")
    dependents: Mapped[list["TaskDependency"]] = relationship("TaskDependency", foreign_keys="TaskDependency.depends_on_task_id", back_populates="prerequisite")
    completion_events: Mapped[list["TaskCompletionEvent"]] = relationship("TaskCompletionEvent", back_populates="task", cascade="all, delete-orphan")

    @property
    def start_date(self) -> datetime | None:
        return self.earliest_start_at

    @property
    def estimated_duration_minutes(self) -> int | None:
        return self.estimated_minutes


class TaskSubtask(Base):
    __tablename__ = "task_subtasks"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    task: Mapped["Task"] = relationship("Task", back_populates="subtasks")


class TaskCompletionEvent(Base):
    __tablename__ = "task_completion_events"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    task_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True)
    event_type: Mapped[str] = mapped_column(String(30), nullable=False)
    previous_status: Mapped[str | None] = mapped_column(String(30), nullable=True)
    next_status: Mapped[str] = mapped_column(String(30), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    task: Mapped["Task"] = relationship("Task", back_populates="completion_events")


class TaskDependency(Base):
    __tablename__ = "task_dependencies"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    task_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True)
    depends_on_task_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True)
    dependency_type: Mapped[str] = mapped_column(String(30), default="finish_to_start", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)

    task: Mapped["Task"] = relationship("Task", foreign_keys=[task_id], back_populates="dependencies")
    prerequisite: Mapped["Task"] = relationship("Task", foreign_keys=[depends_on_task_id], back_populates="dependents")

    from sqlalchemy import UniqueConstraint
    __table_args__ = (
        UniqueConstraint("task_id", "depends_on_task_id", name="uq_task_dependency"),
    )
