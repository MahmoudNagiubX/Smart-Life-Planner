"""add note color and archived_at

Revision ID: e6a4c1b2d9f0
Revises: d8f3a9c2b7e4
Create Date: 2026-04-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e6a4c1b2d9f0"
down_revision: Union[str, None] = "d8f3a9c2b7e4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "notes",
        sa.Column(
            "color_key",
            sa.String(length=30),
            server_default="default",
            nullable=False,
        ),
    )
    op.add_column(
        "notes",
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute(
        "UPDATE notes SET archived_at = now() "
        "WHERE is_archived = true AND archived_at IS NULL"
    )
    op.alter_column("notes", "color_key", server_default=None)


def downgrade() -> None:
    op.drop_column("notes", "archived_at")
    op.drop_column("notes", "color_key")
