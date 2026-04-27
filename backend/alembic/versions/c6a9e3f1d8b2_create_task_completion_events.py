"""create task completion events

Revision ID: c6a9e3f1d8b2
Revises: b4f8a1c6d9e2
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "c6a9e3f1d8b2"
down_revision: Union[str, None] = "b4f8a1c6d9e2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "task_completion_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("task_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("event_type", sa.String(length=30), nullable=False),
        sa.Column("previous_status", sa.String(length=30), nullable=True),
        sa.Column("next_status", sa.String(length=30), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["task_id"], ["tasks.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_task_completion_events_task_id"),
        "task_completion_events",
        ["task_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_task_completion_events_user_id"),
        "task_completion_events",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_task_completion_events_user_id"),
        table_name="task_completion_events",
    )
    op.drop_index(
        op.f("ix_task_completion_events_task_id"),
        table_name="task_completion_events",
    )
    op.drop_table("task_completion_events")
