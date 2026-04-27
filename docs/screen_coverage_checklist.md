# Smart Life Planner - Screen Coverage Checklist

Use this checklist to verify every documented screen and route exists in the Flutter app. Status values:

- Exists: implemented and reachable.
- Partial: UI exists but route, navigation, empty state, or full behavior is incomplete.
- Missing: screen or route still needs to be added.

## App Launch And Auth

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Splash | `/` | Exists | Placeholder route exists; router still starts at welcome. |
| Welcome | `/welcome` | Exists | `WelcomeScreen` is routed. |
| Sign Up | `/sign-up` | Exists | `SignUpScreen` is routed. |
| Sign In | `/sign-in` | Exists | `SignInScreen` is routed. |
| Forgot Password | `/forgot-password` | Exists | `ForgotPasswordScreen` is routed. |
| Email Verification | `/verify-email` | Exists | Added during auth hardening; keep covered for auth completeness. |
| Change Password | `/home/change-password` | Exists | Authenticated route. |

## Onboarding Screens

Current implementation is a single onboarding flow screen. Step 13.2/13.3 should decide whether each documented onboarding page needs a named route or remains an internal step.

| Onboarding step | Expected coverage | Current status | Notes |
| --- | --- | --- | --- |
| Preferred Language | Internal onboarding step | Exists | Arabic / English selection. |
| Country or City | Internal onboarding step | Exists | Manual country/city selection. |
| Prayer Calculation Method | Internal onboarding step | Exists | Method selection. |
| Main Goals | Internal onboarding step | Exists | Study, work, self improvement, fitness, spiritual growth. |
| Preferred Wake-up Time | Internal onboarding step | Exists | Wake time selection. |
| Preferred Sleep Time | Internal onboarding step | Exists | Sleep time selection. |
| Notification Permission | Internal onboarding step | Exists | Permission choice persisted. |
| Microphone Permission | Internal onboarding step | Exists | Permission choice persisted. |
| Location Permission | Internal onboarding step | Exists | Permission choice persisted. |
| Onboarding Summary | Internal onboarding step | Exists | Summary before submit. |

## Main Shell And Core Tabs

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Home | `/home` | Exists | `HomeScreen` routed inside shell. |
| Notes | `/home/notes` | Exists | `NotesScreen` routed inside shell. |
| Habits | `/home/habits` | Exists | `HabitsScreen` routed inside shell. |
| Journal | `/home/journal` | Exists | Placeholder screen is routed. |
| Tasks | `/home/tasks` | Exists | `TasksScreen` routed inside shell. |
| Focus | `/home/focus` | Exists | Current home focus screen routed. |
| Prayer | `/home/prayer` | Exists | Current home prayer screen routed. |
| Profile | `/home/profile` | Exists | `ProfileScreen` routed inside shell. |

## Task And Project Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Task Details | `/home/tasks/:taskId` | Exists | Placeholder route exists until full details implementation. |
| Create/Edit Task | Modal or `/home/tasks/create` / `/home/tasks/:taskId/edit` | Exists | Create sheet exists; create/edit placeholder routes are wired. |
| Project Details | `/home/projects/:projectId` | Exists | Placeholder route exists until full project implementation. |
| Ranked Tasks | `/home/ranked-tasks` | Exists | H-ASAE route exists. |

## Focus Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Focus | `/home/focus` | Exists | Current focus entry screen. |
| Active Focus Session | `/home/focus/session` | Exists | Placeholder route exists. |
| Focus History | `/home/focus/history` | Exists | Placeholder route exists. |

## Spiritual Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Prayer | `/home/prayer` | Exists | Current prayer screen. |
| Prayer History | `/home/prayer/history` | Exists | Placeholder route exists and is reachable from Prayer. |
| Quran Goal | `/home/prayer/quran-goal` | Exists | Daily target/progress screen exists and is reachable from Prayer. |
| Qibla | `/home/prayer/qibla` | Exists | Qibla UI and bearing service placeholder are routed and reachable. |
| Ramadan Mode | `/home/prayer/ramadan` | Exists | Ramadan settings UI is routed and reachable. |
| Prayer Settings | `/home/prayer/settings` | Exists | Prayer settings UI is routed and reachable from Prayer/Profile. |

## Settings And Analytics

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Settings | `/home/settings` | Exists | Placeholder route exists and is reachable from Profile. |
| Notification Settings | `/home/settings/notifications` | Exists | Placeholder route exists and is reachable from Profile. |
| Analytics | `/home/analytics` | Exists | `AnalyticsScreen` routed inside shell. |
| Language and Localization | `/home/settings/language` | Exists | Placeholder route exists and is reachable from Profile. |

## Capture And Voice Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Quick Capture | Modal from Home | Exists | `QuickCaptureSheet` available from home. |
| Voice Capture | `/home/voice-capture` or modal entry | Exists | Screen is routed inside shell. |
| Voice Confirmation | Internal navigation | Exists | `VoiceConfirmationScreen` exists for preview flow. |
| Voice Note | Modal | Exists | `VoiceNoteSheet` exists. |

## Empty, Loading, Error, And Safety States

| Area | Required coverage | Current status | Notes |
| --- | --- | --- | --- |
| No tasks | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No projects | Empty state | Exists | Project details placeholder prevents navigation dead ends until full implementation. |
| No notes | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No habits | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No journal entries | Empty state | Exists | Journal placeholder uses shared empty-state UI. |
| No focus sessions | Empty state | Exists | Focus History placeholder uses shared empty-state UI. |
| No prayer history | Empty state | Exists | Prayer History placeholder uses shared empty-state UI. |
| No analytics data | Empty state | Partial | Confirm current analytics empty state. |
| Reusable loading widget | Loading state | Exists | `AppLoadingState` is shared across routed screens. |
| Reusable error widget | Error state | Exists | `AppErrorState` supports friendly retry states. |
| Destructive confirmations | Dialog coverage | Exists | Shared destructive confirmation dialog is wired into implemented and placeholder flows. |

## Phase 13 Follow-Up

- [x] Step 13.2 adds missing route constants and route definitions.
- [x] Step 13.3 adds placeholders for every Missing screen above.
- [x] Step 13.4 adds consistent empty states.
- [x] Step 13.5 adds consistent loading and error states.
- [x] Step 13.6 adds destructive action confirmations.
