import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ContextSnapshot(Base):
    __tablename__ = "context_snapshots"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
    timezone: Mapped[str] = mapped_column(String(80), default="UTC", nullable=False)
    local_time_block: Mapped[str] = mapped_column(String(20), nullable=False)
    energy_level: Mapped[str | None] = mapped_column(String(20), nullable=True)
    coarse_location_context: Mapped[str | None] = mapped_column(
        String(120), nullable=True
    )
    weather_summary: Mapped[str | None] = mapped_column(String(160), nullable=True)
    device_context: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    __table_args__ = (
        Index("ix_context_snapshots_user_timestamp", "user_id", "timestamp"),
    )
