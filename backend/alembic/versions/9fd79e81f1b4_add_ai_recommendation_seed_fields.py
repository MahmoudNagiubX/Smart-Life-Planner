"""Add AI recommendation seed fields to user settings.

Revision ID: 9fd79e81f1b4
Revises: 2c47a14d9471
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "9fd79e81f1b4"
down_revision: Union[str, None] = "2c47a14d9471"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "ai_goal_tags",
            postgresql.JSON(astext_type=sa.Text()),
            server_default=sa.text("'[]'::json"),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column(
            "ai_daily_rhythm",
            postgresql.JSON(astext_type=sa.Text()),
            server_default=sa.text("'{}'::json"),
            nullable=False,
        ),
    )
    op.add_column(
        "user_settings",
        sa.Column("ai_recommendation_seeded_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("user_settings", "ai_recommendation_seeded_at")
    op.drop_column("user_settings", "ai_daily_rhythm")
    op.drop_column("user_settings", "ai_goal_tags")
