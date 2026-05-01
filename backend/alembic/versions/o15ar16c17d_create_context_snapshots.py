"""create context snapshots

Revision ID: o15ar16c17d
Revises: n15ar12b13c
Create Date: 2026-05-01 00:00:00.000000
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "o15ar16c17d"
down_revision: Union[str, None] = "n15ar12b13c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "context_snapshots",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("timezone", sa.String(length=80), nullable=False),
        sa.Column("local_time_block", sa.String(length=20), nullable=False),
        sa.Column("energy_level", sa.String(length=20), nullable=True),
        sa.Column("coarse_location_context", sa.String(length=120), nullable=True),
        sa.Column("weather_summary", sa.String(length=160), nullable=True),
        sa.Column("device_context", sa.String(length=160), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_context_snapshots_timestamp"),
        "context_snapshots",
        ["timestamp"],
        unique=False,
    )
    op.create_index(
        op.f("ix_context_snapshots_user_id"),
        "context_snapshots",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        "ix_context_snapshots_user_timestamp",
        "context_snapshots",
        ["user_id", "timestamp"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_context_snapshots_user_timestamp", table_name="context_snapshots")
    op.drop_index(op.f("ix_context_snapshots_user_id"), table_name="context_snapshots")
    op.drop_index(op.f("ix_context_snapshots_timestamp"), table_name="context_snapshots")
    op.drop_table("context_snapshots")
