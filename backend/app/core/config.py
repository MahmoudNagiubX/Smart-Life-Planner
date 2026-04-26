from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    GROQ_API_KEY: Optional[str] = None
    GOOGLE_CLIENT_ID: str = ""
    # Apple Sign-In: set to your iOS App Bundle ID (e.g. "com.yourcompany.smartlifeplanner")
    # For web/Android, also add the Services ID if using Apple web auth.
    APPLE_APP_BUNDLE_ID: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
