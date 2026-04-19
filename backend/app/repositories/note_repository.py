import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from app.models.note import Note


async def get_notes(
    db: AsyncSession,
    user_id: uuid.UUID,
    search: str | None = None,
    is_archived: bool = False,
) -> list[Note]:
    query = (
        select(Note)
        .where(Note.user_id == user_id, Note.is_archived == is_archived)
        .order_by(Note.is_pinned.desc(), Note.updated_at.desc())
    )
    if search:
        query = query.where(
            or_(
                Note.title.ilike(f"%{search}%"),
                Note.content.ilike(f"%{search}%"),
            )
        )
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_note_by_id(
    db: AsyncSession, note_id: uuid.UUID, user_id: uuid.UUID
) -> Note | None:
    result = await db.execute(
        select(Note).where(Note.id == note_id, Note.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create_note(
    db: AsyncSession, user_id: uuid.UUID, data: dict
) -> Note:
    note = Note(user_id=user_id, **data)
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return note


async def update_note(
    db: AsyncSession, note: Note, data: dict
) -> Note:
    for key, value in data.items():
        setattr(note, key, value)
    await db.commit()
    await db.refresh(note)
    return note


async def delete_note(db: AsyncSession, note: Note) -> None:
    await db.delete(note)
    await db.commit()