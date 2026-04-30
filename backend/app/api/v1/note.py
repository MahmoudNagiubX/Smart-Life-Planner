import uuid
from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.core.config import settings
from app.schemas.note import (
    NoteCreate,
    NoteActionExtractionResponse,
    NoteSummaryRequest,
    NoteSummaryResponse,
    NoteUpdate,
    NoteResponse,
)
from app.repositories.note_repository import (
    get_notes,
    get_note_by_id,
    create_note,
    update_note,
    delete_note,
)
from app.repositories.task_repository import get_task_by_id
from app.services.ai_service import extract_note_actions, summarize_note_text
from app.services.note_action_extraction_service import (
    fallback_note_action_extraction,
    normalize_note_action_extraction,
)
from app.services.note_summary_service import (
    build_note_summary_source,
    fallback_note_summary,
    normalize_note_summary_result,
)

router = APIRouter(prefix="/notes", tags=["notes"])


@router.get("", response_model=list[NoteResponse])
async def list_notes(
    search: Optional[str] = Query(None),
    tag: Optional[str] = Query(None),
    is_archived: bool = Query(False),
    task_id: Optional[uuid.UUID] = Query(None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if task_id:
        task = await get_task_by_id(db, task_id, current_user.id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
            )
    return await get_notes(db, current_user.id, search, tag, is_archived, task_id)


@router.post("", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_new_note(
    payload: NoteCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = payload.model_dump(exclude_none=True)
    if payload.task_id:
        task = await get_task_by_id(db, payload.task_id, current_user.id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
            )
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


@router.post("/{note_id}/summarize", response_model=NoteSummaryResponse)
async def summarize_existing_note(
    note_id: uuid.UUID,
    payload: NoteSummaryRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Note not found"
        )

    note_text = build_note_summary_source(note)
    if not note_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Note has no readable content to summarize",
        )

    if not settings.GROQ_API_KEY:
        return NoteSummaryResponse(
            **fallback_note_summary(note_text, payload.summary_style)
        )

    try:
        result = await summarize_note_text(note_text, payload.summary_style)
        return NoteSummaryResponse(**normalize_note_summary_result(result))
    except Exception:
        return NoteSummaryResponse(
            **fallback_note_summary(note_text, payload.summary_style)
        )


@router.post("/{note_id}/extract-actions", response_model=NoteActionExtractionResponse)
async def extract_existing_note_actions(
    note_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Note not found"
        )

    note_text = build_note_summary_source(note)
    if not note_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Note has no readable content to extract actions from",
        )

    today = date.today()
    if not settings.GROQ_API_KEY:
        return NoteActionExtractionResponse(
            **fallback_note_action_extraction(note_text, today)
        )

    try:
        result = await extract_note_actions(note_text, today.isoformat())
        return NoteActionExtractionResponse(
            **normalize_note_action_extraction(result)
        )
    except Exception:
        return NoteActionExtractionResponse(
            **fallback_note_action_extraction(note_text, today)
        )


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
    if payload.task_id:
        task = await get_task_by_id(db, payload.task_id, current_user.id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Task not found"
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
