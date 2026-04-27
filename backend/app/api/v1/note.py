import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.note import NoteCreate, NoteUpdate, NoteResponse
from app.repositories.note_repository import (
    get_notes,
    get_note_by_id,
    create_note,
    update_note,
    delete_note,
)

router = APIRouter(prefix="/notes", tags=["notes"])


@router.get("", response_model=list[NoteResponse])
async def list_notes(
    search: Optional[str] = Query(None),
    tag: Optional[str] = Query(None),
    is_archived: bool = Query(False),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_notes(db, current_user.id, search, tag, is_archived)


@router.post("", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_new_note(
    payload: NoteCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = payload.model_dump(exclude_none=True)
    return await create_note(db, current_user.id, data)


@router.get("/{note_id}", response_model=NoteResponse)
async def get_note(
    note_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Note not found"
        )
    return note


@router.patch("/{note_id}", response_model=NoteResponse)
async def update_existing_note(
    note_id: uuid.UUID,
    payload: NoteUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Note not found"
        )
    return await update_note(db, note, payload.model_dump(exclude_none=True))


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_existing_note(
    note_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Note not found"
        )
    await delete_note(db, note)
