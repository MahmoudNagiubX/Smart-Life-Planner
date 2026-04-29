"""Add prayer notification sound setting.

Revision ID: g14r6a7b8c9d
Revises: f14r5a6b7c8d
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "g14r6a7b8c9d"
down_revision: Union[str, None] = "f14r5a6b7c8d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "prayer_notification_sound",
            sa.String(length=20),
            server_default="default",
            nullable=False,
        ),
    )
    op.execute(
        """
        UPDATE user_settings
        SET prayer_notification_sound = 'athan'
        WHERE athan_sound_enabled = true
        """
    )


def downgrade() -> None:
    op.drop_column("user_settings", "prayer_notification_sound")
