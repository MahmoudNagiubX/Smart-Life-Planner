"""add dashboard widget preferences

Revision ID: d7e5f9a2c4b1
Revises: c6a9e3f1d8b2
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "d7e5f9a2c4b1"
down_revision: Union[str, None] = "c6a9e3f1d8b2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

DEFAULT_WIDGETS = (
    '["top_tasks", "next_prayer", "habit_snapshot", "journal_prompt", '
    '"ai_plan", "focus_shortcut", "productivity_score", "quran_goal"]'
)


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "dashboard_widgets",
            postgresql.JSON(astext_type=sa.Text()),
            nullable=False,
            server_default=DEFAULT_WIDGETS,
        ),
    )
    op.alter_column("user_settings", "dashboard_widgets", server_default=None)


def downgrade() -> None:
    op.drop_column("user_settings", "dashboard_widgets")
