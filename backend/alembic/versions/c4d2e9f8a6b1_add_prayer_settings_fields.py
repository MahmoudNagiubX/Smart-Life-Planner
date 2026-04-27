"""Add prayer settings fields.

Revision ID: c4d2e9f8a6b1
Revises: b7a8f2d5c9e1
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "c4d2e9f8a6b1"
down_revision: Union[str, None] = "b7a8f2d5c9e1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "prayer_reminder_minutes_before",
            sa.Integer(),
            server_default="10",
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "athan_sound_enabled",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "athan_sound_enabled")
    op.drop_column("user_settings", "prayer_reminder_minutes_before")
