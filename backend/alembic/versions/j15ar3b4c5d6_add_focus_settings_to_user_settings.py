"""Add focus settings to user settings.

Revision ID: j15ar3b4c5d6
Revises: i15r1a2b3c4d
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "j15ar3b4c5d6"
down_revision: Union[str, None] = "i15r1a2b3c4d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "default_focus_minutes",
            sa.Integer(),
            server_default="25",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "short_break_minutes",
            sa.Integer(),
            server_default="5",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "long_break_minutes",
            sa.Integer(),
            server_default="15",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "sessions_before_long_break",
            sa.Integer(),
            server_default="4",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "continuous_mode_enabled",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "ambient_sound_key",
            sa.String(length=40),
            server_default="silence",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "distraction_free_mode_enabled",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "distraction_free_mode_enabled")
    op.drop_column("user_settings", "ambient_sound_key")
    op.drop_column("user_settings", "continuous_mode_enabled")
    op.drop_column("user_settings", "sessions_before_long_break")
    op.drop_column("user_settings", "long_break_minutes")
    op.drop_column("user_settings", "short_break_minutes")
    op.drop_column("user_settings", "default_focus_minutes")
