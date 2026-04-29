"""Add real Ramadan mode settings fields.

Revision ID: e14r4a5b6c7d
Revises: d13r4e5f6a7b
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "e14r4a5b6c7d"
down_revision: Union[str, None] = "d13r4e5f6a7b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "iftar_reminder_enabled",
            sa.Boolean(),
            server_default=sa.true(),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "taraweeh_tracking_enabled",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "fasting_tracker_enabled",
            sa.Boolean(),
            server_default=sa.true(),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "fasting_tracker_enabled")
    op.drop_column("user_settings", "taraweeh_tracking_enabled")
    op.drop_column("user_settings", "iftar_reminder_enabled")
