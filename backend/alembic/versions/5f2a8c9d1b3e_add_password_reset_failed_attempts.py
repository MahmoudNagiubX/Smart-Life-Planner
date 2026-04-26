"""Add password reset failed attempts.

Revision ID: 5f2a8c9d1b3e
Revises: 9fd79e81f1b4
Create Date: 2026-04-27 02:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "5f2a8c9d1b3e"
down_revision: Union[str, None] = "9fd79e81f1b4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "password_resets",
        sa.Column(
            "failed_attempts",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.alter_column("password_resets", "failed_attempts", server_default=None)


def downgrade() -> None:
    op.drop_column("password_resets", "failed_attempts")
