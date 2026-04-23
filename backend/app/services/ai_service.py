import json
from groq import AsyncGroq
from app.core.config import settings
from app.core.logging import logger

client = AsyncGroq(api_key=settings.GROQ_API_KEY)

MODEL = "llama-3.1-8b-instant"

PARSE_TASK_PROMPT = """
You are a smart task parser for a productivity app.
Extract structured task data from the user's natural language input.

Return ONLY a valid JSON object with these fields:
- title: string (required, the core task title, clean and concise)
- priority: string (one of: low, medium, high — infer from urgency words)
- due_at: string or null (ISO 8601 datetime if date/time mentioned, else null)
- estimated_minutes: integer or null (if duration mentioned, else null)
- category: string or null (if category/context mentioned, else null)
- confidence: string (one of: high, medium, low — your confidence in the extraction)

Rules:
- Today is {today}
- If user says "tomorrow", compute the correct date
- If user says "tonight" use 20:00 local time
- If user says "urgent" or "ASAP" set priority to high
- Never invent data that was not in the input
- Return ONLY the JSON object, no markdown, no explanation, no backticks
"""

NEXT_ACTION_PROMPT = """
You are a smart productivity assistant.
Given the user's pending tasks, suggest the single best next action.

Return ONLY a valid JSON object with these fields:
- task_id: string (the id of the recommended task)
- title: string (task title)
- reason: string (short explanation why this task now, max 15 words)
- confidence: string (high, medium, or low)

Rules:
- Prioritize high priority tasks
- Prioritize tasks with due dates closest to now
- Keep reason brief and helpful
- Return ONLY the JSON object, no markdown, no backticks
"""

DAILY_PLAN_PROMPT = """
You are a smart daily planner.
Given the user's pending tasks and prayer times, suggest a simple ordered daily plan.

Return ONLY a valid JSON array of objects with these fields:
- task_id: string
- title: string
- suggested_time: string (HH:MM format)
- duration_minutes: integer
- reason: string (max 10 words)

Rules:
- Never schedule tasks during prayer times
- Respect task priorities and due dates
- Keep the plan realistic, max 6 tasks
- Return ONLY the JSON array, no markdown, no backticks
"""


async def parse_task_from_text(input_text: str, today: str) -> dict:
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not configured")

    try:
        response = await client.chat.completions.create(
            model=MODEL,
            messages=[
                {
                    "role": "system",
                    "content": PARSE_TASK_PROMPT.format(today=today),
                },
                {"role": "user", "content": input_text},
            ],
            temperature=0.1,
            max_tokens=300,
        )
        raw = response.choices[0].message.content.strip()
        # Strip markdown backticks if model added them
        raw = raw.replace("```json", "").replace("```", "").strip()
        return json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"AI parse_task JSON error: {e}")
        return {"title": input_text, "priority": "medium", "confidence": "low"}
    except Exception as e:
        logger.error(f"AI parse_task error: {e}")
        raise


async def get_next_action(tasks: list[dict]) -> dict:
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not configured")

    if not tasks:
        return {
            "task_id": None,
            "title": None,
            "reason": "No pending tasks",
            "confidence": "high",
        }

    try:
        tasks_text = json.dumps(tasks[:10], default=str)
        response = await client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": NEXT_ACTION_PROMPT},
                {"role": "user", "content": f"My pending tasks: {tasks_text}"},
            ],
            temperature=0.2,
            max_tokens=200,
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        return json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"AI next_action JSON error: {e}")
        return {
            "task_id": None,
            "reason": "Could not determine next action",
            "confidence": "low",
        }
    except Exception as e:
        logger.error(f"AI next_action error: {e}")
        raise


async def generate_daily_plan(tasks: list[dict], prayers: list[dict]) -> list[dict]:
    if not settings.GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY not configured")

    try:
        context = json.dumps(
            {"tasks": tasks[:10], "prayers": prayers}, default=str
        )
        response = await client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": DAILY_PLAN_PROMPT},
                {"role": "user", "content": context},
            ],
            temperature=0.2,
            max_tokens=500,
        )
        raw = response.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        return json.loads(raw)
    except json.JSONDecodeError as e:
        logger.error(f"AI daily_plan JSON error: {e}")
        return []
    except Exception as e:
        logger.error(f"AI daily_plan error: {e}")
        raise
