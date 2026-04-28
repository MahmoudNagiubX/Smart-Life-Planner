"""add reminder preferences to user settings

Revision ID: b15b2c3d4e5f
Revises: a15b1c2d3e4f
Create Date: 2026-04-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b15b2c3d4e5f"
down_revision: Union[str, None] = "a15b1c2d3e4f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


REMINDER_PREFERENCES_DEFAULT = (
    '{"channels": {"local": true, "push": true, "in_app": true, '
    '"email": false}, "types": {"task": true, "habit": true, "note": true, '
    '"quran_goal": true, "prayer": true, "focus_prompt": true, '
    '"bedtime": true, "ai_suggestion": true, "location": false}, '
    '"quiet_hours": {"enabled": false, "start": "22:00", "end": "07:00"}, '
    '"timing": {"prayer_minutes_before": 10, "bedtime_minutes_before": 30, '
    '"focus_prompt_minutes_before": 10}}'
)


def upgrade() -> None:
    op.add_column(
        "user_settings",
        sa.Column(
            "reminder_preferences",
            sa.JSON(),
            nullable=False,
            server_default=sa.text(f"'{REMINDER_PREFERENCES_DEFAULT}'::json"),
        ),
    )
    op.alter_column("user_settings", "reminder_preferences", server_default=None)


def downgrade() -> None:
    op.drop_column("user_settings", "reminder_preferences")
