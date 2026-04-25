from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.api.v1.auth import get_current_user
from app.schemas.voice import (
    VoiceTranscriptionResponse,
    VoiceTaskParseRequest,
    VoiceTaskParseResponse,
    VoiceTranscribeAndParseResponse,
    ParsedVoiceTask,
)
from app.services.voice_service import (
    transcribe_audio_with_groq,
    parse_tasks_from_transcript,
)
from app.core.config import settings
from app.core.logging import logger

router = APIRouter(prefix="/voice", tags=["voice"])

MAX_AUDIO_SIZE = 25 * 1024 * 1024  # 25 MB


def _check_ai_configured():
    if not settings.GROQ_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not configured",
        )


def _get_dates() -> tuple[str, str]:
    today = date.today()
    tomorrow = today + timedelta(days=1)
    return today.isoformat(), tomorrow.isoformat()


@router.post("/transcribe", response_model=VoiceTranscriptionResponse)
async def transcribe_voice(
    audio: UploadFile = File(...),
    language: str = Form("auto"),
    current_user=Depends(get_current_user),
):
    _check_ai_configured()

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file is empty",
        )
    if len(audio_bytes) > MAX_AUDIO_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file too large. Maximum size is 25 MB.",
        )

    try:
        result = await transcribe_audio_with_groq(
            audio_bytes,
            audio.filename or "audio.m4a",
            language,
        )
        return VoiceTranscriptionResponse(**result)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        if "rate_limit" in str(e).lower() or "429" in str(e):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Voice AI limit reached. Try again later.",
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Transcription failed. Please try again.",
        )


@router.post("/parse-tasks", response_model=VoiceTaskParseResponse)
async def parse_voice_tasks(
    payload: VoiceTaskParseRequest,
    current_user=Depends(get_current_user),
):
    _check_ai_configured()
    today, tomorrow = _get_dates()

    try:
        result = await parse_tasks_from_transcript(
            payload.transcribed_text,
            payload.language or "auto",
            today,
            tomorrow,
        )
        tasks = [ParsedVoiceTask(**t) for t in result.get("tasks", [])]
        return VoiceTaskParseResponse(
            detected_intent=result.get("detected_intent", "unknown_intent"),
            confidence=result.get("confidence", "low"),
            tasks=tasks,
            confirmation_required=result.get("confirmation_required", True),
            display_text=result.get("display_text", "Review your tasks."),
        )
    except Exception as e:
        logger.error(f"Voice parse error: {e}")
        if "rate_limit" in str(e).lower() or "429" in str(e):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="AI limit reached. Try again later.",
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Task parsing failed. Please try again.",
        )


@router.post("/transcribe-and-parse", response_model=VoiceTranscribeAndParseResponse)
async def transcribe_and_parse(
    audio: UploadFile = File(...),
    language: str = Form("auto"),
    current_user=Depends(get_current_user),
):
    _check_ai_configured()

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file is empty",
        )
    if len(audio_bytes) > MAX_AUDIO_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Audio file too large. Maximum size is 25 MB.",
        )

    today, tomorrow = _get_dates()

    try:
        # Step 1: Transcribe
        transcription = await transcribe_audio_with_groq(
            audio_bytes,
            audio.filename or "audio.m4a",
            language,
        )
        transcribed_text = transcription["transcribed_text"]
        detected_language = transcription.get("language", language)

        # Step 2: Parse tasks
        result = await parse_tasks_from_transcript(
            transcribed_text,
            detected_language,
            today,
            tomorrow,
        )

        tasks = [ParsedVoiceTask(**t) for t in result.get("tasks", [])]

        return VoiceTranscribeAndParseResponse(
            transcribed_text=transcribed_text,
            language=detected_language,
            provider=transcription.get("provider", "groq_whisper_large_v3_turbo"),
            detected_intent=result.get("detected_intent", "unknown_intent"),
            confidence=result.get("confidence", "low"),
            tasks=tasks,
            confirmation_required=result.get("confirmation_required", True),
            display_text=result.get("display_text", "Review your tasks."),
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )
    except Exception as e:
        logger.error(f"Transcribe and parse error: {e}")
        if "rate_limit" in str(e).lower() or "429" in str(e):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Voice AI limit reached. Try again later.",
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Voice processing failed. Please try again.",
        )