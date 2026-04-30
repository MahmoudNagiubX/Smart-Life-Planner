# Smart Notes Privacy and AI Rules

## Scope

This document defines the privacy and safety rules for Smart Note features:

- OCR from note images
- handwriting extraction from note images
- AI note summaries
- AI action extraction from notes

These rules are part of the product contract. Smart notes must help the user without surprising them.

## What Content Is Sent To AI

AI note summary and AI action extraction may send the selected note's readable text to the backend AI service.

The backend source text can include:

- note title
- note body
- checklist item text
- structured note block text

The backend must not intentionally send:

- raw image files for the current local OCR/handwriting flow
- JWT tokens
- passwords
- unrelated notes
- unrelated tasks, reminders, or account records
- analytics payloads containing raw note content

The backend truncates smart-note AI input to a bounded length before sending it to the AI provider.

## OCR Local vs Backend

OCR from images runs on-device in the Flutter app using the local ML Kit text recognition flow.

Handwriting extraction also uses the same on-device best-effort text recognition pipeline. It must never claim perfect handwriting recognition. If confidence is unavailable or low, the app must tell the user to review the preview carefully.

The current implementation does not upload note images for OCR or handwriting extraction.

If backend image OCR is added later, it must be documented here before release and must still use preview-before-write.

## Preview Before Write

Every smart-note feature must show a preview before modifying user data.

Required preview behavior:

- OCR text appears in an editable preview.
- handwriting text appears in an editable preview.
- AI summaries appear in an editable preview.
- AI action extraction appears as editable suggestions.

Nothing may be inserted, replaced, copied into app data, or converted into tasks/reminders until the user chooses an explicit action.

## User Confirmation Rule

All smart-note writes require user confirmation.

Allowed confirmed actions:

- append extracted text to a note
- replace note content after confirmation
- copy preview text to clipboard
- insert an edited summary into a note
- create selected edited task/reminder suggestions
- append selected checklist suggestions

The user must be able to cancel any smart-note preview without saving changes.

## No Silent Task or Reminder Creation

AI action extraction must never silently create tasks, reminders, checklist items, calendar items, or focus sessions.

Every extracted action must include:

- editable title
- editable type
- editable due date when present
- editable reminder time when present
- confidence
- reason
- `requires_confirmation = true`

The user must be able to reject individual suggestions before creation.

## Failure Handling

Smart-note failures must be safe and friendly.

The app must handle:

- no image found
- OCR failure
- AI unavailable
- low confidence
- network failure

Failure states must not expose raw provider errors. Where useful, the app should offer:

- retry
- manual editing fallback
- clear review guidance

Backend smart-note errors should use structured safe messages, not raw exceptions.

## Analytics Rule

Raw note content must not be used for analytics.

Allowed analytics:

- counts of smart-note actions
- success/failure counts
- feature type usage, such as OCR or summary
- timing/performance metrics without note text

Not allowed:

- storing raw note text in analytics
- sending note body to product analytics
- logging AI prompts containing private notes
- logging raw AI provider responses that include private note content

## Current Feature Audit

| Feature | Processing location | User preview | Writes automatically | Manual fallback |
| --- | --- | --- | --- | --- |
| OCR from images | On-device | Yes | No | Yes |
| Handwriting extraction | On-device, best effort | Yes | No | Yes |
| AI note summary | Backend AI with fallback | Yes | No | Yes |
| AI action extraction | Backend AI with fallback | Yes | No | Yes |

## Manual Verification Checklist

- Run OCR on a note image and confirm text is shown before append/replace.
- Run handwriting extraction and confirm confidence/review guidance appears.
- Run AI summary and confirm Insert is required before note content changes.
- Run AI action extraction and confirm no task/reminder is created until selected and confirmed.
- Reject one extracted action and confirm it is not created.
- Disconnect network and confirm smart-note AI failure does not crash the app.
- Verify failure UI offers retry or manual editing fallback.
