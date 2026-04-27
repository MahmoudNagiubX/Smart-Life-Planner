from datetime import date, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from app.api.v1.auth import get_current_user
from app.schemas.voice import (
    VoiceNoteOrganizeResponse,
    VoiceTranscriptionResponse,
    VoiceTaskParseRequest,
    VoiceTaskParseResponse,
    VoiceTranscribeAndParseResponse,
    ParsedVoiceTask,
)
from app.services.voice_service import (
    organize_note_from_transcript,
    transcribe_audio_with_groq,
    parse_tasks_from_transcript,
)
from app.services.voice_fallback import (
    normalize_voice_task_parse,
    voice_task_parse_fallback,
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


def _voice_task_parse_response(result: dict) -> VoiceTaskParseResponse:
    tasks = [ParsedVoiceTask(**t) for t in result.get("tasks", [])]
    confirmation_required = result.get("confirmation_required", True)
    return VoiceTaskParseResponse(
        detected_intent=result.get("detected_intent", "unknown_intent"),
        confidence=result.get("confidence", "low"),
        tasks=tasks,
        confirmation_required=confirmation_required,
        requires_confirmation=result.get(
            "requires_confirmation",
            confirmation_required,
        ),
        display_text=result.get("display_text", "Review your tasks."),
        fallback_reason=result.get("fallback_reason"),
    )


def _voice_transcribe_parse_response(
    *,
    transcribed_text: str,
    language: str | None,
    provider: str,
    result: dict,
) -> VoiceTranscribeAndParseResponse:
    tasks = [ParsedVoiceTask(**t) for t in result.get("tasks", [])]
    confirmation_required = result.get("confirmation_required", True)
    return VoiceTranscribeAndParseResponse(
        transcribed_text=transcribed_text,
        language=language,
        provider=provider,
        detected_intent=result.get("detected_intent", "unknown_intent"),
        confidence=result.get("confidence", "low"),
        tasks=tasks,
        confirmation_required=confirmation_required,
        requires_confirmation=result.get(
            "requires_confirmation",
            confirmation_required,
        ),
        display_text=result.get("display_text", "Review your tasks."),
        fallback_reason=result.get("fallback_reason"),
    )


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
    if not settings.GROQ_API_KEY:
        result = voice_task_parse_fallback(
            payload.transcribed_text,
            "ai_not_configured",
        )
        return _voice_task_parse_response(result)

    today, tomorrow = _get_dates()

    try:
        result = await parse_tasks_from_transcript(
            payload.transcribed_text,
            payload.language or "auto",
            today,
            tomorrow,
        )
        return _voice_task_parse_response(
            normalize_voice_task_parse(result, payload.transcribed_text)
        )
    except Exception as e:
        logger.error(
            "Voice parse error",
            exc_info=True,
            extra={
                "failure_area": "ai_service",
                "exception_type": type(e).__name__,
                "safe_context": "voice_parse_tasks",
            },
        )
        if "rate_limit" in str(e).lower() or "429" in str(e):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="AI limit reached. Try again later.",
            )
        return _voice_task_parse_response(
            voice_task_parse_fallback(
                payload.transcribed_text,
                "voice_parse_failure",
            )
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
        try:
            result = await parse_tasks_from_transcript(
                transcribed_text,
                detected_language,
                today,
                tomorrow,
            )
            result = normalize_voice_task_parse(result, transcribed_text)
        except Exception as e:
            logger.error(
                "Voice parse after transcription failed",
                exc_info=True,
                extra={
                    "failure_area": "ai_service",
                    "exception_type": type(e).__name__,
                    "safe_context": "voice_transcribe_and_parse_parse_step",
                },
            )
            result = voice_task_parse_fallback(
                transcribed_text,
                "voice_parse_failure",
            )

        return _voice_transcribe_parse_response(
            transcribed_text=transcribed_text,
            language=detected_language,
            provider=transcription.get("provider", "groq_whisper_large_v3_turbo"),
            result=result,
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


@router.post("/transcribe-note", response_model=VoiceNoteOrganizeResponse)
async def transcribe_note(
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
        # Step 1: Transcribe
        transcription = await transcribe_audio_with_groq(
            audio_bytes,
            audio.filename or "audio.m4a",
            language,
        )
        transcribed_text = transcription["transcribed_text"]
        detected_language = transcription.get("language", language)

        # Step 2: Organize into structured note
        note_data = await organize_note_from_transcript(
            transcribed_text,
            detected_language,
        )

        return VoiceNoteOrganizeResponse(
            transcribed_text=transcribed_text,
            language=detected_language,
            provider=transcription.get("provider", "groq_whisper_large_v3_turbo"),
            title=note_data.get("title"),
            content=note_data.get("content", transcribed_text),
            note_type=note_data.get("note_type", "text"),
            tags=note_data.get("tags", []),
            confidence=note_data.get("confidence", "low"),
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )
    except Exception as e:
        logger.error(f"Voice note error: {e}")
        if "rate_limit" in str(e).lower() or "429" in str(e):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Voice AI limit reached. Try again later.",
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Voice note processing failed. Please try again.",
        )
