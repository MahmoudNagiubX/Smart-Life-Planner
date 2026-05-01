"""Add status field to prayer_logs for missed prayer tracking.

Revision ID: l15ar10a11b
Revises: k15ar6c7d8e9
Create Date: 2026-05-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "l15ar10a11b"
down_revision: Union[str, None] = "k15ar6c7d8e9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add status column with a default of NULL (unknown/unset)
    # Valid values: prayed_on_time, prayed_late, missed, excused
    op.add_column(
        "prayer_logs",
        sa.Column(
            "status",
            sa.String(20),
            nullable=True,
        ),
    )
    # Backfill: completed logs get 'prayed_on_time', incomplete stay NULL
    op.execute(
        """
        UPDATE prayer_logs
        SET status = 'prayed_on_time'
        WHERE completed = true AND status IS NULL
        """
    )


def downgrade() -> None:
    op.drop_column("prayer_logs", "status")
