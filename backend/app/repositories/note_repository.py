import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from app.models.note import Note


def normalize_note_tag(tag: str | None) -> str | None:
    if tag is None:
        return None
    clean = tag.strip().lower().lstrip("#")
    return clean or None


async def get_notes(
    db: AsyncSession,
    user_id: uuid.UUID,
    search: str | None = None,
    tag: str | None = None,
    is_archived: bool = False,
) -> list[Note]:
    archived_filter = (
        Note.archived_at.is_not(None)
        if is_archived
        else Note.archived_at.is_(None)
    )
    query = (
        select(Note)
        .where(Note.user_id == user_id, archived_filter)
        .order_by(Note.is_pinned.desc(), Note.updated_at.desc())
    )
    if search:
        query = query.where(
            or_(
                Note.title.ilike(f"%{search}%"),
                Note.content.ilike(f"%{search}%"),
            )
        )
    normalized_tag = normalize_note_tag(tag)
    if normalized_tag:
        query = query.where(Note.tags.contains([normalized_tag]))
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_note_by_id(
    db: AsyncSession, note_id: uuid.UUID, user_id: uuid.UUID
) -> Note | None:
    result = await db.execute(
        select(Note).where(Note.id == note_id, Note.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_note(db: AsyncSession, user_id: uuid.UUID, data: dict) -> Note:
    note = Note(user_id=user_id, **data)
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return note


async def update_note(db: AsyncSession, note: Note, data: dict) -> Note:
    if "is_archived" in data:
        is_archived = bool(data["is_archived"])
        data["archived_at"] = datetime.now(timezone.utc) if is_archived else None

    for key, value in data.items():
        setattr(note, key, value)
    await db.commit()
    await db.refresh(note)
    return note


async def delete_note(db: AsyncSession, note: Note) -> None:
    await db.delete(note)
    await db.commit()
