# Smart Life Planner - Screen Coverage Checklist

Use this checklist to verify every documented screen and route exists in the Flutter app. Status values:

- Exists: implemented and reachable.
- Partial: UI exists but route, navigation, empty state, or full behavior is incomplete.
- Missing: screen or route still needs to be added.

## App Launch And Auth

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Splash | `/` | Missing | Route constant exists, but router starts at welcome and no splash screen is wired. |
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
| Journal | `/home/journal` | Missing | Needs screen or placeholder. |
| Tasks | `/home/tasks` | Exists | `TasksScreen` routed inside shell. |
| Focus | `/home/focus` | Exists | Current home focus screen routed. |
| Prayer | `/home/prayer` | Exists | Current home prayer screen routed. |
| Profile | `/home/profile` | Exists | `ProfileScreen` routed inside shell. |

## Task And Project Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Task Details | `/home/tasks/:taskId` | Missing | Needs details screen or placeholder. |
| Create/Edit Task | Modal or `/home/tasks/create` / `/home/tasks/:taskId/edit` | Partial | `CreateTaskSheet` exists, no edit/details route yet. |
| Project Details | `/home/projects/:projectId` | Missing | Needs project details screen or placeholder. |
| Ranked Tasks | `/home/ranked-tasks` | Exists | H-ASAE route exists. |

## Focus Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Focus | `/home/focus` | Exists | Current focus entry screen. |
| Active Focus Session | `/home/focus/session` | Missing | Needs route or placeholder. |
| Focus History | `/home/focus/history` | Missing | Needs route or placeholder. |

## Spiritual Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Prayer | `/home/prayer` | Exists | Current prayer screen. |
| Prayer History | `/home/prayer/history` | Missing | Needs route or placeholder. |
| Quran Goal | `/home/prayer/quran-goal` | Missing | Planned for Phase 14. |
| Qibla | `/home/prayer/qibla` | Missing | Planned for Phase 14. |
| Ramadan Mode | `/home/prayer/ramadan` | Missing | Planned for Phase 14. |
| Prayer Settings | `/home/settings/prayer` or `/home/prayer/settings` | Missing | Needs route and screen. |

## Settings And Analytics

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Settings | `/home/settings` | Missing | Profile menu exists, dedicated screen not routed. |
| Notification Settings | `/home/settings/notifications` | Missing | Needs route or placeholder. |
| Analytics | `/home/analytics` | Exists | `AnalyticsScreen` routed inside shell. |
| Language and Localization | `/home/settings/language` | Missing | Needs route or placeholder. |

## Capture And Voice Screens

| Screen | Expected route | Current status | Notes |
| --- | --- | --- | --- |
| Quick Capture | Modal from Home | Exists | `QuickCaptureSheet` available from home. |
| Voice Capture | `/home/voice-capture` or modal entry | Partial | Screen exists, route coverage should be confirmed. |
| Voice Confirmation | Internal navigation | Exists | `VoiceConfirmationScreen` exists for preview flow. |
| Voice Note | Modal | Exists | `VoiceNoteSheet` exists. |

## Empty, Loading, Error, And Safety States

| Area | Required coverage | Current status | Notes |
| --- | --- | --- | --- |
| No tasks | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No projects | Empty state | Missing | Confirm after project screens/routes. |
| No notes | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No habits | Empty state | Partial | Confirm visual consistency in Step 13.4. |
| No journal entries | Empty state | Missing | Requires Journal screen. |
| No focus sessions | Empty state | Missing | Requires Focus History screen. |
| No prayer history | Empty state | Missing | Requires Prayer History screen. |
| No analytics data | Empty state | Partial | Confirm current analytics empty state. |
| Reusable loading widget | Loading state | Missing | Planned Step 13.5. |
| Reusable error widget | Error state | Missing | Planned Step 13.5. |
| Destructive confirmations | Dialog coverage | Partial | Planned Step 13.6. |

## Phase 13 Follow-Up

- [ ] Step 13.2 adds missing route constants and route definitions.
- [ ] Step 13.3 adds placeholders for every Missing screen above.
- [ ] Step 13.4 adds consistent empty states.
- [ ] Step 13.5 adds consistent loading and error states.
- [ ] Step 13.6 adds destructive action confirmations.
