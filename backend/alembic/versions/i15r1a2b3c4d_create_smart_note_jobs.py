"""Create smart note jobs table.

Revision ID: i15r1a2b3c4d
Revises: h14r7a8b9c0d
Create Date: 2026-04-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "i15r1a2b3c4d"
down_revision: Union[str, None] = "h14r7a8b9c0d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "smart_note_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("note_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("job_type", sa.String(length=40), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column(
            "input_attachment_id",
            postgresql.UUID(as_uuid=True),
            nullable=True,
        ),
        sa.Column("result_text", sa.Text(), nullable=True),
        sa.Column("result_json", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("error_code", sa.String(length=80), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint(
            "job_type IN ('ocr', 'handwriting', 'summary', 'action_extraction')",
            name="ck_smart_note_jobs_job_type",
        ),
        sa.CheckConstraint(
            "status IN ('pending', 'processing', 'completed', 'failed')",
            name="ck_smart_note_jobs_status",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["note_id"], ["notes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["input_attachment_id"],
            ["note_attachments.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_smart_note_jobs_user_id"),
        "smart_note_jobs",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_smart_note_jobs_note_id"),
        "smart_note_jobs",
        ["note_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_smart_note_jobs_input_attachment_id"),
        "smart_note_jobs",
        ["input_attachment_id"],
        unique=False,
    )
    op.create_index(
        "ix_smart_note_jobs_user_status",
        "smart_note_jobs",
        ["user_id", "status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_smart_note_jobs_user_status", table_name="smart_note_jobs")
    op.drop_index(
        op.f("ix_smart_note_jobs_input_attachment_id"),
        table_name="smart_note_jobs",
    )
    op.drop_index(op.f("ix_smart_note_jobs_note_id"), table_name="smart_note_jobs")
    op.drop_index(op.f("ix_smart_note_jobs_user_id"), table_name="smart_note_jobs")
    op.drop_table("smart_note_jobs")
