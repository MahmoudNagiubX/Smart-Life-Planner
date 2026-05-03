import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr, field_validator


class UserRegister(BaseModel):
    email: EmailStr
    full_name: str
    password: str

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("full_name")
    @classmethod
    def full_name_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Full name cannot be empty")
        return v.strip()


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    auth_provider: str
    is_active: bool
    is_verified: bool          # ← now exposed to frontend
    onboarding_completed: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    full_name: str

    @field_validator("full_name")
    @classmethod
    def full_name_valid(cls, v: str) -> str:
        cleaned = " ".join(v.split())
        if not cleaned:
            raise ValueError("Full name cannot be empty")
        if len(cleaned) > 120:
            raise ValueError("Full name is too long")
        return cleaned


class RegisterResponse(UserResponse):
    message: str = "Account created. Check your email for the verification code."
    development_code: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str

    @field_validator("code")
    @classmethod
    def code_is_digits(cls, v: str) -> str:
        if not v.strip().isdigit() or len(v.strip()) != 6:
            raise ValueError("Code must be a 6-digit number")
        return v.strip()


class ResendVerificationRequest(BaseModel):
    email: EmailStr


# ── Password Reset ──────────────────────────────────────────────────────────

class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class VerifyResetCodeRequest(BaseModel):
    email: EmailStr
    code: str

    @field_validator("code")
    @classmethod
    def code_is_digits(cls, v: str) -> str:
        if not v.strip().isdigit() or len(v.strip()) != 6:
            raise ValueError("Code must be a 6-digit number")
        return v.strip()


class SetNewPasswordRequest(BaseModel):
    reset_token: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class GoogleSignInRequest(BaseModel):
    id_token: str

    @field_validator("id_token")
    @classmethod
    def id_token_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("id_token cannot be empty")
        return v.strip()


class AppleSignInRequest(BaseModel):
    """
    Apple Sign-In payload sent from the Flutter client.

    Fields:
        identity_token  — JWT issued by Apple's identity server. Must be
                          verified against Apple's public keys.
        full_name       — Optional; Apple ONLY sends the user's name on the
                          VERY FIRST sign-in. The client must cache and send
                          it on that first request.
        email           — Optional; Apple only sends email on first sign-in.
                          May be a private relay address if the user chose
                          "Hide My Email".
    """

    identity_token: str
    full_name: str | None = None
    email: EmailStr | None = None

    @field_validator("identity_token")
    @classmethod
    def identity_token_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("identity_token cannot be empty")
        return v.strip()

    @field_validator("full_name")
    @classmethod
    def full_name_trimmed(cls, v: str | None) -> str | None:
        if v is None:
            return v
        stripped = " ".join(v.split())
        return stripped or None


# ── Account Deletion ────────────────────────────────────────────────────────

class DeleteAccountRequest(BaseModel):
    """
    Account deletion request.

    For email/password accounts: supply `password` to confirm identity.
    For social accounts (Google/Apple): supply `confirmation` = "DELETE"
    (exact string) as the confirmation phrase.

    Exactly one of `password` or `confirmation` must be provided.
    """

    password: str | None = None
    confirmation: str | None = None

    @field_validator("confirmation")
    @classmethod
    def confirmation_must_be_delete(cls, v: str | None) -> str | None:
        if v is not None and v.strip().upper() != "DELETE":
            raise ValueError("Confirmation must be the word DELETE")
        return v.strip().upper() if v else v

