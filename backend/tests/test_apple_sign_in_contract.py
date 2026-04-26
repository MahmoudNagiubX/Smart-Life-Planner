import pytest
from pydantic import ValidationError

from app.schemas.user import AppleSignInRequest, GoogleSignInRequest


def test_apple_sign_in_request_trims_safe_optional_fields():
    payload = AppleSignInRequest(
        identity_token="  header.payload.signature  ",
        full_name="  Jane   Appleseed  ",
        email="jane@example.com",
    )

    assert payload.identity_token == "header.payload.signature"
    assert payload.full_name == "Jane Appleseed"
    assert str(payload.email) == "jane@example.com"


@pytest.mark.parametrize(
    "payload",
    [
        {"identity_token": ""},
        {"identity_token": "   "},
        {"identity_token": "header.payload.signature", "email": "not-an-email"},
    ],
)
def test_apple_sign_in_request_rejects_invalid_payload(payload):
    with pytest.raises(ValidationError):
        AppleSignInRequest(**payload)


def test_google_sign_in_request_trims_id_token():
    payload = GoogleSignInRequest(id_token="  google-id-token  ")

    assert payload.id_token == "google-id-token"


@pytest.mark.parametrize("id_token", ["", "   "])
def test_google_sign_in_request_rejects_blank_token(id_token):
    with pytest.raises(ValidationError):
        GoogleSignInRequest(id_token=id_token)
