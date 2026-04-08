from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from app.api.v1.router import router
from app.core.logging import setup_logging, logger
from app.core.exceptions import (
    http_exception_handler,
    validation_exception_handler,
    unhandled_exception_handler,
)

setup_logging()

app = FastAPI(
    title="Smart Life Planner API",
    version="0.1.0",
    description="AI-native personal operating system — backend core",
)

app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

app.include_router(router)


@app.get("/health")
def health_check():
    logger.info("Health check called")
    return {"status": "ok", "service": "smart-life-planner-api"}