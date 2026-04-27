"""Add Quran goal and progress tables.

Revision ID: d8f3a9c2b7e4
Revises: c4d2e9f8a6b1
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "d8f3a9c2b7e4"
down_revision: Union[str, None] = "c4d2e9f8a6b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "quran_goals",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("daily_page_target", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(op.f("ix_quran_goals_user_id"), "quran_goals", ["user_id"])

    op.create_table(
        "quran_progress",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("progress_date", sa.Date(), nullable=False),
        sa.Column("pages_completed", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "progress_date",
            name="uq_quran_progress_user_date",
        ),
    )
    op.create_index(
        op.f("ix_quran_progress_user_id"),
        "quran_progress",
        ["user_id"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_quran_progress_user_id"), table_name="quran_progress")
    op.drop_table("quran_progress")
    op.drop_index(op.f("ix_quran_goals_user_id"), table_name="quran_goals")
    op.drop_table("quran_goals")
