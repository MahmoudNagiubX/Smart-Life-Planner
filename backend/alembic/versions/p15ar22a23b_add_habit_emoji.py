"""add habit emoji

Revision ID: p15ar22a23b
Revises: o15ar16c17d
Create Date: 2026-05-03 00:00:00.000000
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "p15ar22a23b"
down_revision: Union[str, None] = "o15ar16c17d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("habits", sa.Column("emoji", sa.String(length=32), nullable=True))


def downgrade() -> None:
    op.drop_column("habits", "emoji")
