from fastapi import APIRouter
from app.api.v1 import auth, settings, tasks, dashboard, note, habit, focus, prayer, ai

router = APIRouter(prefix="/api/v1")
router.include_router(auth.router)
router.include_router(settings.router)
router.include_router(tasks.router)
router.include_router(dashboard.router)
router.include_router(note.router)
router.include_router(habit.router)
router.include_router(focus.router)
router.include_router(prayer.router)
router.include_router(ai.router)
