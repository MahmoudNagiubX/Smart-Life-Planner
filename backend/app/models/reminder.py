import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Reminder(Base):
    __tablename__ = "reminders"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    target_type: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    target_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, index=True
    )
    reminder_type: Mapped[str] = mapped_column(String(60), nullable=False, index=True)
    scheduled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    recurrence_rule: Mapped[str | None] = mapped_column(Text, nullable=True)
    timezone: Mapped[str] = mapped_column(String(80), default="UTC", nullable=False)
    status: Mapped[str] = mapped_column(
        String(30), default="scheduled", nullable=False, index=True
    )
    snooze_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    channel: Mapped[str] = mapped_column(String(30), default="local", nullable=False)
    priority: Mapped[str] = mapped_column(String(20), default="normal", nullable=False)
    is_persistent: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    persistent_interval_minutes: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    persistent_max_occurrences: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    persistent_occurrences_sent: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    dismissed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
