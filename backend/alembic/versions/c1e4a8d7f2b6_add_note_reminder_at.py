"""add note reminder_at

Revision ID: c1e4a8d7f2b6
Revises: b9d3e7c6a5f1
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c1e4a8d7f2b6"
down_revision: Union[str, None] = "b9d3e7c6a5f1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "notes",
        sa.Column("reminder_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f("ix_notes_reminder_at"), "notes", ["reminder_at"])


def downgrade() -> None:
    op.drop_index(op.f("ix_notes_reminder_at"), table_name="notes")
    op.drop_column("notes", "reminder_at")
