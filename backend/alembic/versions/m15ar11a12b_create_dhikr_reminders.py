"""create dhikr reminders

Revision ID: m15ar11a12b
Revises: l15ar10a11b
Create Date: 2026-05-01 00:00:00.000000
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "m15ar11a12b"
down_revision: Union[str, None] = "l15ar10a11b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "dhikr_reminders",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("phrase", sa.Text(), nullable=True),
        sa.Column("schedule_time", sa.Time(timezone=False), nullable=False),
        sa.Column("recurrence_rule", sa.String(length=80), nullable=False),
        sa.Column("timezone", sa.String(length=80), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_dhikr_reminders_user_id"),
        "dhikr_reminders",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_dhikr_reminders_user_id"), table_name="dhikr_reminders")
    op.drop_table("dhikr_reminders")
