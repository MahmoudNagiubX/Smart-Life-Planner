from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.logging import logger


SENSITIVE_FIELD_PARTS = {
    "authorization",
    "cookie",
    "password",
    "secret",
    "token",
    "code",
    "audio",
    "transcript",
    "content",
    "journal",
    "note",
}


def _request_context(request: Request) -> dict:
    return {
        "request_id": getattr(request.state, "request_id", None),
        "endpoint": request.url.path,
        "method": request.method,
    }


def _validation_fields(exc: RequestValidationError) -> list[dict[str, str]]:
    fields: list[dict[str, str]] = []
    for error in exc.errors():
        field = " -> ".join(str(location) for location in error["loc"])
        if any(part in field.lower() for part in SENSITIVE_FIELD_PARTS):
            field = "sensitive_field"
        fields.append(
            {
                "field": field,
                "message": str(error["msg"]),
                "error_type": str(error.get("type", "validation_error")),
            }
        )
    return fields


async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException,
) -> JSONResponse:
    context = {
        **_request_context(request),
        "status_code": exc.status_code,
        "error_type": "http_exception",
        "safe_context": "HTTP exception handled",
    }
    log_method = logger.error if exc.status_code >= 500 else logger.info
    log_method("HTTP request rejected", extra=context)

    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail
            if exc.status_code < 500
            else "Something went wrong. Please try again.",
            "request_id": context["request_id"],
        },
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    fields = _validation_fields(exc)
    logger.warning(
        "Request validation failed",
        extra={
            **_request_context(request),
            "status_code": 422,
            "error_type": "validation_error",
            "safe_context": "Request validation failed",
            "fields": fields,
        },
    )

    return JSONResponse(
        status_code=422,
        content={
            "detail": "Please check the submitted fields.",
            "errors": fields,
            "request_id": getattr(request.state, "request_id", None),
        },
    )


async def unhandled_exception_handler(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    request_id = getattr(request.state, "request_id", None)
    logger.error(
        "Unhandled server exception",
        exc_info=True,
        extra={
            **_request_context(request),
            "status_code": 500,
            "exception_type": type(exc).__name__,
            "safe_context": "Unhandled exception converted to safe response",
        },
    )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Something went wrong. Please try again.",
            "request_id": request_id,
        },
    )
