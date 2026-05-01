"""add fasting log type fields

Revision ID: n15ar12b13c
Revises: m15ar11a12b
Create Date: 2026-05-01 00:00:00.000000
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "n15ar12b13c"
down_revision: Union[str, None] = "m15ar11a12b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "ramadan_fasting_logs",
        sa.Column(
            "fast_type",
            sa.String(length=30),
            server_default="ramadan",
            nullable=False,
        ),
    )
    op.add_column(
        "ramadan_fasting_logs",
        sa.Column("makeup_for_date", sa.Date(), nullable=True),
    )
    op.alter_column("ramadan_fasting_logs", "fast_type", server_default=None)


def downgrade() -> None:
    op.drop_column("ramadan_fasting_logs", "makeup_for_date")
    op.drop_column("ramadan_fasting_logs", "fast_type")
