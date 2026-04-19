from fastapi import APIRouter
from app.api.v1 import auth, settings, tasks, dashboard, notes, habits, focus

router = APIRouter(prefix="/api/v1")
router.include_router(auth.router)
router.include_router(settings.router)
router.include_router(tasks.router)
router.include_router(dashboard.router)
router.include_router(notes.router)
router.include_router(habits.router)
router.include_router(focus.router)