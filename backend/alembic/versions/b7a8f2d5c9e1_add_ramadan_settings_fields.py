"""Add Ramadan settings fields.

Revision ID: b7a8f2d5c9e1
Revises: 5f2a8c9d1b3e
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "b7a8f2d5c9e1"
down_revision: Union[str, None] = "5f2a8c9d1b3e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "ramadan_mode_enabled",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "suhoor_reminder_enabled",
            sa.Boolean(),
            server_default=sa.true(),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "suhoor_reminder_minutes_before_fajr",
            sa.Integer(),
            server_default="45",
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "suhoor_reminder_minutes_before_fajr")
    op.drop_column("user_settings", "suhoor_reminder_enabled")
    op.drop_column("user_settings", "ramadan_mode_enabled")
