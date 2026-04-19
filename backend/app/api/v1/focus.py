import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.focus import (
    FocusSessionCreate,
    FocusSessionResponse,
    FocusAnalyticsResponse,
)
from app.repositories.focus_repository import (
    get_active_session,
    get_sessions,
    get_session_by_id,
    create_session,
    complete_session,
    cancel_session,
    get_focus_analytics,
)
from app.repositories.task_repository import get_task_by_id

router = APIRouter(prefix="/focus", tags=["focus"])


@router.post(
    "/sessions",
    response_model=FocusSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def start_session(
    payload: FocusSessionCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await get_active_session(db, current_user.id)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You already have an active focus session",
        )
    if payload.task_id:
        task = await get_task_by_id(db, payload.task_id, current_user.id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found",
            )
    return await create_session(db, current_user.id, payload.model_dump())


@router.get("/sessions", response_model=list[FocusSessionResponse])
async def list_sessions(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_sessions(db, current_user.id)


@router.get("/sessions/active", response_model=FocusSessionResponse)
async def get_active(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_active_session(db, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active session",
        )
    return session


@router.patch(
    "/sessions/{session_id}/complete",
    response_model=FocusSessionResponse,
)
async def finish_session(
    session_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_session_by_id(db, session_id, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )
    return await complete_session(db, session)


@router.patch(
    "/sessions/{session_id}/cancel",
    response_model=FocusSessionResponse,
)
async def abort_session(
    session_id: uuid.UUID,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    session = await get_session_by_id(db, session_id, current_user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )
    if session.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session is not active",
        )
    return await cancel_session(db, session)


@router.get("/analytics", response_model=FocusAnalyticsResponse)
async def focus_analytics(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_focus_analytics(db, current_user.id)