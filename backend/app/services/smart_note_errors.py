from fastapi import HTTPException, status


def smart_note_error(
    code: str,
    message: str,
    *,
    status_code: int = status.HTTP_400_BAD_REQUEST,
    retryable: bool = False,
    manual_fallback: str = "Edit the note manually.",
) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={
            "code": code,
            "message": message,
            "retryable": retryable,
            "manual_fallback": manual_fallback,
        },
    )
