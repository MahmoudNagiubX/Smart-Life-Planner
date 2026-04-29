"""Add Quran progress target pages snapshot.

Revision ID: h14r7a8b9c0d
Revises: g14r6a7b8c9d
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "h14r7a8b9c0d"
down_revision: Union[str, None] = "g14r6a7b8c9d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "quran_progress",
        sa.Column(
            "target_pages",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.execute(
        """
        UPDATE quran_progress AS progress
        SET target_pages = COALESCE(goal.daily_page_target, 0)
        FROM quran_goals AS goal
        WHERE goal.user_id = progress.user_id
        """
    )


def downgrade() -> None:
    op.drop_column("quran_progress", "target_pages")
