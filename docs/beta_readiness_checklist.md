# Smart Life Planner - Beta Readiness Checklist

Use this checklist on a real Android device against the intended backend environment before calling the MVP beta-ready. Mark every item as pass or fail, then fix any failed core flow before release.

## Authentication

- [ ] Email/password registration works
- [ ] Email/password login works
- [ ] Google sign-in works
- [ ] Apple sign-in architecture is safely disabled or configured
- [ ] Email verification flow works
- [ ] Password reset by email code works
- [ ] Change password works
- [ ] Logout works
- [ ] Token persists across app restarts
- [ ] Auth errors show friendly messages

## Core Task Flows

- [ ] Create task works
- [ ] Edit task works
- [ ] Complete task works
- [ ] Delete task works as soft delete
- [ ] Subtasks work
- [ ] Projects work
- [ ] Task reminders can be scheduled
- [ ] Empty state shows when no tasks exist

## Prayer Module

- [ ] Prayer times load correctly for user location
- [ ] All 5 prayers display with correct times
- [ ] Mark prayer as complete works
- [ ] Mark prayer as incomplete works
- [ ] Prayer notifications fire at correct times
- [ ] Prayer calculation method change updates times

## Notifications

- [ ] Task reminder fires at correct time
- [ ] Completing a task cancels its reminder
- [ ] Deleting a task cancels its reminder
- [ ] Changing task due/reminder time reschedules reminder
- [ ] Habit reminder works where enabled
- [ ] Archiving or deleting habit cancels its reminder
- [ ] Prayer reminder works
- [ ] Changing prayer settings reschedules prayer reminders
- [ ] Notification permission denied state does not crash the app

## AI Features

- [ ] Quick Capture AI parse works for clear input
- [ ] AI confirmation sheet shows before task creation
- [ ] Low-confidence AI parse requires confirmation
- [ ] AI failure falls back to manual entry gracefully
- [ ] Daily plan generates correctly
- [ ] Next action card loads on home
- [ ] No low-confidence AI result silently creates important data

## Voice Features

- [ ] VoiceCaptureScreen opens
- [ ] Microphone permission is requested correctly
- [ ] Voice states are visible: idle, listening, processing, transcript preview, success, failed
- [ ] English voice command transcribes correctly
- [ ] Arabic voice command transcribes correctly
- [ ] Transcript preview is editable before creating tasks
- [ ] Voice failure shows retry and manual fallback
- [ ] Unsupported or unclear voice intent requires confirmation

## Stability & Safety

- [ ] Structured backend error logging works
- [ ] Logs include request ID when available
- [ ] Logs do not include passwords, bearer tokens, secrets, raw audio, or full note/journal content
- [ ] Mobile crash monitoring is initialized
- [ ] Backend request timing logs are visible
- [ ] Slow request warning threshold works in development
- [ ] No raw backend errors are shown to users
- [ ] No unhandled crashes in core flows

## Onboarding

- [ ] Fresh user completes onboarding successfully
- [ ] Returning user skips onboarding
- [ ] Default habits are created from selected goals
- [ ] Dashboard reflects onboarding choices
- [ ] AI recommendation seed profile changes with selected goals and rhythm
- [ ] Onboarding choices can be edited later through settings or profile flows

## Sync And Data Ownership

- [ ] User-owned records cannot be accessed by another user
- [ ] Sync convergence has no blocker in MVP flows
- [ ] App restart preserves expected local notification schedules
- [ ] Logout clears sensitive local session state

## General

- [ ] Dark mode works correctly
- [ ] Light mode works correctly
- [ ] Arabic language works with RTL layout
- [ ] English language works with LTR layout
- [ ] App works on a real Android device using backend local IP
- [ ] MVP scope is still controlled
- [ ] Monitoring hooks are enabled
- [ ] No major crash exists in auth, onboarding, home, tasks, prayer, AI, or voice flows

## Test Session Notes

- Tester: `________________`
- Device / Android version: `________________`
- App build/version: `________________`
- Backend environment: `________________`
- Test date/time: `________________`
- Total passed: `____`
- Total failed: `____`
- Follow-up issues created: `________________`
