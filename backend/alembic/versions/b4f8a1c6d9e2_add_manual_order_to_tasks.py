"""add manual order to tasks

Revision ID: b4f8a1c6d9e2
Revises: a7c9e2d4f6b8
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b4f8a1c6d9e2"
down_revision: Union[str, None] = "a7c9e2d4f6b8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "tasks",
        sa.Column("manual_order", sa.Integer(), nullable=False, server_default="0"),
    )
    op.alter_column("tasks", "manual_order", server_default=None)


def downgrade() -> None:
    op.drop_column("tasks", "manual_order")
