import uuid
from time import perf_counter

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.logging import logger


SLOW_REQUEST_THRESHOLD_MS = 1000


class RequestIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class RequestTimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        started_at = perf_counter()
        status_code = 500

        try:
            response = await call_next(request)
            status_code = response.status_code
            return response
        except Exception:
            duration_ms = self._duration_ms(started_at)
            logger.error(
                "API request failed before response",
                exc_info=True,
                extra=self._log_context(
                    request=request,
                    status_code=status_code,
                    duration_ms=duration_ms,
                    failure_area=self._failure_area(request, status_code),
                ),
            )
            raise
        finally:
            duration_ms = self._duration_ms(started_at)
            failure_area = self._failure_area(request, status_code)
            context = self._log_context(
                request=request,
                status_code=status_code,
                duration_ms=duration_ms,
                failure_area=failure_area,
            )
            if duration_ms >= SLOW_REQUEST_THRESHOLD_MS:
                logger.warning("Slow API request", extra=context)
            elif failure_area:
                logger.warning("API request failure tracked", extra=context)
            else:
                logger.info("API request completed", extra=context)

    @staticmethod
    def _duration_ms(started_at: float) -> int:
        return int((perf_counter() - started_at) * 1000)

    @staticmethod
    def _log_context(
        *,
        request: Request,
        status_code: int,
        duration_ms: int,
        failure_area: str | None,
    ) -> dict:
        context = {
            "request_id": getattr(request.state, "request_id", None),
            "endpoint": request.url.path,
            "method": request.method,
            "status_code": status_code,
            "duration_ms": duration_ms,
            "slow_threshold_ms": SLOW_REQUEST_THRESHOLD_MS,
            "safe_context": "Request timing recorded",
        }
        if failure_area:
            context["failure_area"] = failure_area
        return context

    @staticmethod
    def _failure_area(request: Request, status_code: int) -> str | None:
        if status_code < 400:
            return None
        path = request.url.path
        if status_code in {401, 403}:
            return "auth"
        if path.startswith("/api/v1/ai") or path.startswith("/api/v1/voice"):
            return "ai_service"
        if path.startswith("/api/v1/scheduling"):
            return "sync"
        if "notification" in path or "reminder" in path:
            return "notification_scheduling"
        return "api"
