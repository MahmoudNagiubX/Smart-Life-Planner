"""create unified reminders table

Revision ID: a15b1c2d3e4f
Revises: d7e5f9a2c4b1
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "a15b1c2d3e4f"
down_revision: Union[str, None] = "d7e5f9a2c4b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "reminders",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("target_type", sa.String(length=40), nullable=False),
        sa.Column("target_id", sa.UUID(), nullable=True),
        sa.Column("reminder_type", sa.String(length=60), nullable=False),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("recurrence_rule", sa.Text(), nullable=True),
        sa.Column("timezone", sa.String(length=80), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("snooze_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("channel", sa.String(length=30), nullable=False),
        sa.Column("priority", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("cancelled_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_reminders_cancelled_at"), "reminders", ["cancelled_at"])
    op.create_index(op.f("ix_reminders_reminder_type"), "reminders", ["reminder_type"])
    op.create_index(op.f("ix_reminders_scheduled_at"), "reminders", ["scheduled_at"])
    op.create_index(op.f("ix_reminders_status"), "reminders", ["status"])
    op.create_index(op.f("ix_reminders_target_id"), "reminders", ["target_id"])
    op.create_index(op.f("ix_reminders_target_type"), "reminders", ["target_type"])
    op.create_index(op.f("ix_reminders_user_id"), "reminders", ["user_id"])


def downgrade() -> None:
    op.drop_index(op.f("ix_reminders_user_id"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_target_type"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_target_id"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_status"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_scheduled_at"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_reminder_type"), table_name="reminders")
    op.drop_index(op.f("ix_reminders_cancelled_at"), table_name="reminders")
    op.drop_table("reminders")
