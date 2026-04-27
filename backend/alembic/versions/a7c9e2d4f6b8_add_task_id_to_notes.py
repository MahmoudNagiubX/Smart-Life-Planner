"""add task id to notes

Revision ID: a7c9e2d4f6b8
Revises: c1e4a8d7f2b6
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "a7c9e2d4f6b8"
down_revision: Union[str, None] = "c1e4a8d7f2b6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "notes",
        sa.Column("task_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index(op.f("ix_notes_task_id"), "notes", ["task_id"])
    op.create_foreign_key(
        "fk_notes_task_id_tasks",
        "notes",
        "tasks",
        ["task_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_notes_task_id_tasks", "notes", type_="foreignkey")
    op.drop_index(op.f("ix_notes_task_id"), table_name="notes")
    op.drop_column("notes", "task_id")
