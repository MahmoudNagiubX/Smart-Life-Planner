import uuid
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload
from app.models.note import Note, NoteAttachment


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
        .options(selectinload(Note.attachments))
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
        select(Note)
        .options(selectinload(Note.attachments))
        .where(Note.id == note_id, Note.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_note(db: AsyncSession, user_id: uuid.UUID, data: dict) -> Note:
    attachments_data = data.pop("attachments", [])
    note = Note(user_id=user_id, **data)
    for attachment_data in attachments_data:
        note.attachments.append(NoteAttachment(**attachment_data))
    db.add(note)
    await db.commit()
    await db.refresh(note)
    note = await get_note_by_id(db, note.id, user_id)
    if note is None:
        raise RuntimeError("Created note could not be reloaded")
    return note


async def update_note(db: AsyncSession, note: Note, data: dict) -> Note:
    attachments_data = data.pop("attachments", None)
    clear_reminder_at = bool(data.pop("clear_reminder_at", False))
    if clear_reminder_at:
        data["reminder_at"] = None

    if "is_archived" in data:
        is_archived = bool(data["is_archived"])
        data["archived_at"] = datetime.now(timezone.utc) if is_archived else None
        if is_archived:
            data["reminder_at"] = None

    for key, value in data.items():
        setattr(note, key, value)

    if attachments_data is not None:
        note.attachments.clear()
        for attachment_data in attachments_data:
            note.attachments.append(NoteAttachment(**attachment_data))

    await db.commit()
    await db.refresh(note)
    reloaded = await get_note_by_id(db, note.id, note.user_id)
    if reloaded is not None:
        return reloaded
    return note


async def delete_note(db: AsyncSession, note: Note) -> None:
    await db.delete(note)
    await db.commit()
