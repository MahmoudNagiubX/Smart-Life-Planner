import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.reminder_preferences import default_reminder_preferences


class AuthProvider(str, enum.Enum):
    email = "email"
    google = "google"
    apple = "apple"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    auth_provider: Mapped[AuthProvider] = mapped_column(
        Enum(AuthProvider, name="authprovider"),
        nullable=False,
        default=AuthProvider.email,
    )
    provider_user_id: Mapped[str | None] = mapped_column(
        String(255), nullable=True, index=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    settings: Mapped["UserSettings"] = relationship(
        "UserSettings", back_populates="user", uselist=False
    )


class UserSettings(Base):
    __tablename__ = "user_settings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    timezone: Mapped[str] = mapped_column(String(100), default="UTC", nullable=False)
    language: Mapped[str] = mapped_column(String(10), default="en", nullable=False)
    prayer_calculation_method: Mapped[str] = mapped_column(
        String(50), default="MWL", nullable=False
    )
    prayer_location_lat: Mapped[float | None] = mapped_column(nullable=True)
    prayer_location_lng: Mapped[float | None] = mapped_column(nullable=True)
    prayer_reminder_minutes_before: Mapped[int] = mapped_column(
        Integer, default=10, nullable=False
    )
    athan_sound_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    prayer_notification_sound: Mapped[str] = mapped_column(
        String(20), default="default", nullable=False
    )
    theme: Mapped[str] = mapped_column(String(20), default="dark", nullable=False)
    notifications_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    reminder_preferences: Mapped[dict] = mapped_column(
        JSON,
        default=default_reminder_preferences,
        nullable=False,
    )
    # Onboarding and personalization
    country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    goals: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    wake_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    sleep_time: Mapped[str | None] = mapped_column(String(5), nullable=True)
    work_study_windows: Mapped[list[dict]] = mapped_column(
        JSON, default=list, nullable=False
    )
    microphone_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    location_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    onboarding_completed: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    ai_goal_tags: Mapped[list[str]] = mapped_column(
        JSON, default=list, nullable=False
    )
    ai_daily_rhythm: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    ai_recommendation_seeded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    dashboard_widgets: Mapped[list[str]] = mapped_column(
        JSON, default=list, nullable=False
    )
    ramadan_mode_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    suhoor_reminder_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    suhoor_reminder_minutes_before_fajr: Mapped[int] = mapped_column(
        Integer, default=45, nullable=False
    )
    iftar_reminder_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    taraweeh_tracking_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    fasting_tracker_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    default_focus_minutes: Mapped[int] = mapped_column(
        Integer, default=25, nullable=False
    )
    short_break_minutes: Mapped[int] = mapped_column(
        Integer, default=5, nullable=False
    )
    long_break_minutes: Mapped[int] = mapped_column(
        Integer, default=15, nullable=False
    )
    sessions_before_long_break: Mapped[int] = mapped_column(
        Integer, default=4, nullable=False
    )
    continuous_mode_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    ambient_sound_key: Mapped[str] = mapped_column(
        String(40), default="silence", nullable=False
    )
    distraction_free_mode_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="settings")
