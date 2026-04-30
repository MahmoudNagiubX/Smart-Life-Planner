"""Add task Pomodoro progress fields.

Revision ID: k15ar6c7d8e9
Revises: j15ar3b4c5d6
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "k15ar6c7d8e9"
down_revision: Union[str, None] = "j15ar3b4c5d6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "tasks",
        sa.Column(
            "estimated_pomodoros",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.add_column(
        "tasks",
        sa.Column(
            "completed_pomodoros",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.execute(
        """
        UPDATE tasks
        SET estimated_pomodoros = CEIL(estimated_minutes::numeric / 25)::int
        WHERE estimated_minutes IS NOT NULL
          AND estimated_minutes > 0
          AND estimated_pomodoros = 0
        """
    )


def downgrade() -> None:
    op.drop_column("tasks", "completed_pomodoros")
    op.drop_column("tasks", "estimated_pomodoros")
