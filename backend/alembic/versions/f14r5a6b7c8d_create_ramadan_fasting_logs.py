"""Create Ramadan fasting logs table.

Revision ID: f14r5a6b7c8d
Revises: e14r4a5b6c7d
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "f14r5a6b7c8d"
down_revision: Union[str, None] = "e14r4a5b6c7d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "ramadan_fasting_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("fasting_date", sa.Date(), nullable=False),
        sa.Column("fasted", sa.Boolean(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "fasting_date",
            name="uq_ramadan_fasting_log_user_date",
        ),
    )
    op.create_index(
        op.f("ix_ramadan_fasting_logs_user_id"),
        "ramadan_fasting_logs",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_ramadan_fasting_logs_fasting_date"),
        "ramadan_fasting_logs",
        ["fasting_date"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_ramadan_fasting_logs_fasting_date"),
        table_name="ramadan_fasting_logs",
    )
    op.drop_index(
        op.f("ix_ramadan_fasting_logs_user_id"),
        table_name="ramadan_fasting_logs",
    )
    op.drop_table("ramadan_fasting_logs")
