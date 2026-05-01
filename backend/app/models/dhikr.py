import uuid
from datetime import datetime, time

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class DhikrReminder(Base):
    __tablename__ = "dhikr_reminders"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    phrase: Mapped[str | None] = mapped_column(Text, nullable=True)
    schedule_time: Mapped[time] = mapped_column(Time(timezone=False), nullable=False)
    recurrence_rule: Mapped[str] = mapped_column(String(80), default="daily", nullable=False)
    timezone: Mapped[str] = mapped_column(String(80), default="UTC", nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )
