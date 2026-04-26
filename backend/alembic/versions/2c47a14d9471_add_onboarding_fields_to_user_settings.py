"""Add onboarding fields to user settings.

Revision ID: 2c47a14d9471
Revises: 26cfe83e6179
Create Date: 2026-04-26 17:19:14.610621

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '2c47a14d9471'
down_revision: Union[str, None] = '26cfe83e6179'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("user_settings", sa.Column("country", sa.String(length=100), nullable=True))
    op.add_column("user_settings", sa.Column("city", sa.String(length=100), nullable=True))
    op.add_column(
        "user_settings",
        sa.Column(
            "goals",
            postgresql.JSON(astext_type=sa.Text()),
            server_default=sa.text("'[]'::json"),
            nullable=False,
        ),
    )
    op.add_column("user_settings", sa.Column("wake_time", sa.String(length=5), nullable=True))
    op.add_column("user_settings", sa.Column("sleep_time", sa.String(length=5), nullable=True))
    op.add_column(
        "user_settings",
        sa.Column(
            "work_study_windows",
            postgresql.JSON(astext_type=sa.Text()),
            server_default=sa.text("'[]'::json"),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column("microphone_enabled", sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    op.add_column(
        "user_settings",
        sa.Column("location_enabled", sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    op.add_column(
        "user_settings",
        sa.Column("onboarding_completed", sa.Boolean(), server_default=sa.false(), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "onboarding_completed")
    op.drop_column("user_settings", "location_enabled")
    op.drop_column("user_settings", "microphone_enabled")
    op.drop_column("user_settings", "work_study_windows")
    op.drop_column("user_settings", "sleep_time")
    op.drop_column("user_settings", "wake_time")
    op.drop_column("user_settings", "goals")
    op.drop_column("user_settings", "city")
    op.drop_column("user_settings", "country")
