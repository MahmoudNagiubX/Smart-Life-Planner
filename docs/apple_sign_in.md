# Apple Sign-In Architecture

## Backend Contract

`POST /auth/apple`

Request body:

```json
{
  "identity_token": "apple-jwt",
  "full_name": "Optional First Login Name",
  "email": "optional@example.com"
}
```

Response body:

```json
{
  "access_token": "app-jwt",
  "token_type": "bearer"
}
```

The backend verifies the Apple identity token against Apple's JWKS, requires
`RS256`, validates issuer `https://appleid.apple.com`, validates the configured
audience, and uses the `sub` claim as the stable Apple provider user id.

## Configuration

Set this environment variable on the backend:

```env
APPLE_APP_BUNDLE_ID=com.smartlifeplanner.smartLifePlanner
```

For iOS native Sign in with Apple, this must match the app bundle identifier
used by Apple Developer configuration. The current iOS bundle identifier is
`com.smartlifeplanner.smartLifePlanner`.

Before testing on a physical iOS device:

1. Enable **Sign in with Apple** for the App ID in the Apple Developer portal.
2. Confirm Xcode shows the Sign in with Apple capability for the Runner target.
3. Keep `mobile/ios/Runner/Runner.entitlements` assigned to Debug, Profile,
   and Release builds.
4. Set the backend `APPLE_APP_BUNDLE_ID` to the exact same bundle identifier.

If a future web or Android Apple flow is added, configure the corresponding
Apple Services ID and extend backend audience validation deliberately. Do not
reuse the native iOS bundle identifier for web authentication.

## Account Rules

- New Apple users are created with `auth_provider=apple`.
- `provider_user_id` stores Apple's stable `sub` claim.
- `hashed_password` remains `null` for Apple users.
- Email/password accounts are not silently linked to Apple accounts.
- If Apple returns a private relay email, it is treated as the account email.
- If Apple does not return an email on a later sign-in, the backend falls back
  to the existing Apple provider id lookup.

## Flutter Notes

- The Apple button is shown only on iOS and macOS.
- The client sends `full_name` and `email` when Apple provides them, which
  normally happens only on the first authorization.
- Unsupported platforms should continue to hide Apple sign-in until a dedicated
  web flow is configured.
- Android remains Google/email-only for now.

## Manual Test

- Confirm the Apple button is hidden on Android.
- Confirm Flutter web analysis/build does not fail from `dart:io` imports in
  the sign-in screen.
- Confirm the Apple button appears on iOS or macOS.
- Submit a malformed token to `/auth/apple` and verify it returns a safe
  validation error without logging token contents.
- Test first sign-in and repeat sign-in on a real Apple-enabled build when an
  Apple Developer configuration is available.
