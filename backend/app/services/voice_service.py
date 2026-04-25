import json
import tempfile
import os
from groq import AsyncGroq
from app.core.config import settings
from app.core.logging import logger

client = AsyncGroq(api_key=settings.GROQ_API_KEY)

STT_MODEL = "whisper-large-v3-turbo"
INTENT_MODEL = "llama-3.1-8b-instant"

MAX_AUDIO_BYTES = 25 * 1024 * 1024  # 25 MB Groq limit

TASK_PARSER_PROMPT = """
You are a smart voice task parser for a productivity app.
The user spoke naturally in Arabic or English. Extract ALL tasks from the transcript.

Return ONLY a valid JSON object:
{{
  "detected_intent": "bulk_task_capture",
  "confidence": "high",
  "tasks": [
    {{
      "title": "...",
      "description": null,
      "due_date": "YYYY-MM-DD or null",
      "due_time": "HH:MM or null",
      "priority": "low|medium|high",
      "estimated_duration_minutes": null,
      "project": null,
      "category": null,
      "subtasks": [
        {{"title": "...", "completed": false}}
      ]
    }}
  ],
  "confirmation_required": true,
  "display_text": "I found X tasks. Please review before saving."
}}

Rules:
- Today is {today}
- Support Arabic and English naturally
- Extract ALL tasks mentioned, even casual ones
- Split big tasks into subtasks when user gives obvious sub-items
- "tomorrow" = {tomorrow}
- "tonight" = today at 20:00
- "urgent" or "ASAP" = high priority
- Default priority = medium
- Do NOT invent deadlines if not mentioned
- For non-task intents (focus, prayer, etc.) set detected_intent accordingly and tasks = []
- Supported non-task intents: start_focus_session, get_next_prayer, get_daily_plan, get_next_action
- For start_focus_session add duration_minutes to first task parameters
- Task titles should be clean and concise
- Return ONLY JSON, no markdown, no backticks
"""


async def transcribe_audio_with_groq(
    audio_bytes: bytes,
    filename: str,
    language: str = "auto",
) -> dict:
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not configured")

    if len(audio_bytes) > MAX_AUDIO_BYTES:
        raise ValueError("Audio file too large. Maximum size is 25 MB.")

    tmp_path = None
    try:
        suffix = os.path.splitext(filename)[1] or ".m4a"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        with open(tmp_path, "rb") as audio_file:
            kwargs = {
                "file": (filename, audio_file),
                "model": STT_MODEL,
                "response_format": "verbose_json",
            }
            if language and language != "auto":
                kwargs["language"] = language

            transcription = await client.audio.transcriptions.create(**kwargs)

        return {
            "transcribed_text": transcription.text.strip(),
            "language": getattr(transcription, "language", language),
            "duration_seconds": getattr(transcription, "duration", None),
            "provider": "groq_whisper_large_v3_turbo",
        }
    except Exception as e:
        logger.error(f"Groq transcription error: {e}")
        raise
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)


async def parse_tasks_from_transcript(
    transcribed_text: str,
    language: str,
    today: str,
    tomorrow: str,
) -> dict:
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not configured")

    try:
        response = await client.chat.completions.create(
            model=INTENT_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": TASK_PARSER_PROMPT.format(
                        today=today, tomorrow=tomorrow
                    ),
                },
                {
                    "role": "user",
                    "content": f"Language: {language}\nTranscript: {transcribed_text}",
                },
            ],
            temperature=0.1,
            max_tokens=800,
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        return json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"Voice task parse JSON error: {e}")
        return {
            "detected_intent": "unknown_intent",
            "confidence": "low",
            "tasks": [],
            "confirmation_required": True,
            "display_text": "Could not parse tasks. Please try again.",
        }
    except Exception as e:
        logger.error(f"Voice task parse error: {e}")
        raise