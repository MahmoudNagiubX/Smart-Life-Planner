"""create note attachments table

Revision ID: b9d3e7c6a5f1
Revises: f5c8e2a9b1d4
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b9d3e7c6a5f1"
down_revision: Union[str, None] = "f5c8e2a9b1d4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "note_attachments",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("note_id", sa.UUID(), nullable=False),
        sa.Column("file_url", sa.String(length=1024), nullable=True),
        sa.Column("local_path", sa.String(length=1024), nullable=True),
        sa.Column("file_type", sa.String(length=80), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["note_id"], ["notes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_note_attachments_note_id"),
        "note_attachments",
        ["note_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_note_attachments_note_id"), table_name="note_attachments")
    op.drop_table("note_attachments")
