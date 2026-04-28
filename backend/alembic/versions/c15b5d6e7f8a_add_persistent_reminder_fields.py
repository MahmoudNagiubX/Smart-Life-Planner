"""add persistent reminder fields

Revision ID: c15b5d6e7f8a
Revises: b15b2c3d4e5f
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c15b5d6e7f8a"
down_revision: Union[str, None] = "b15b2c3d4e5f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "reminders",
        sa.Column(
            "is_persistent",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "reminders",
        sa.Column("persistent_interval_minutes", sa.Integer(), nullable=True),
    )
    op.add_column(
        "reminders",
        sa.Column("persistent_max_occurrences", sa.Integer(), nullable=True),
    )
    op.add_column(
        "reminders",
        sa.Column(
            "persistent_occurrences_sent",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
    )
    op.add_column(
        "reminders",
        sa.Column("dismissed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f("ix_reminders_dismissed_at"), "reminders", ["dismissed_at"])
    op.alter_column("reminders", "is_persistent", server_default=None)
    op.alter_column("reminders", "persistent_occurrences_sent", server_default=None)


def downgrade() -> None:
    op.drop_index(op.f("ix_reminders_dismissed_at"), table_name="reminders")
    op.drop_column("reminders", "dismissed_at")
    op.drop_column("reminders", "persistent_occurrences_sent")
    op.drop_column("reminders", "persistent_max_occurrences")
    op.drop_column("reminders", "persistent_interval_minutes")
    op.drop_column("reminders", "is_persistent")
