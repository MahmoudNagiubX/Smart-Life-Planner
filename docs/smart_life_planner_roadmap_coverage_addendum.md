# Smart Life Planner — Roadmap Coverage Addendum

This addendum continues the **Smart Life Planner — AI Coding Execution Roadmap** after the original roadmap ends at **Phase 12, Step 12.10 — Public Beta / Soft Launch Preparation**.

The purpose of this addendum is to close the remaining gap between the coding roadmap and the full software documentation.

It should be used with Claude or any AI coding assistant as a continuation roadmap.

---

# 1) How the AI must use this addendum

## Operating mode
The AI helping with implementation must follow these rules:

1. Continue from the original roadmap after **Phase 12, Step 12.10**.
2. Work on **one phase at a time**.
3. Inside each phase, work on **one step at a time**.
4. Do not rewrite existing working modules unless required for integration or safety.
5. Treat this addendum as a **coverage completion layer**, not a replacement for the original roadmap.
6. Prefer small, safe patches over large rewrites.
7. Every step must end with:
   - what was implemented
   - which files were created or changed
   - what still remains
   - how to test it manually
8. If implementation requires a decision, choose the simplest clean implementation that matches the software documentation.
9. Do not add advanced non-MVP features unless the step explicitly requires them.
10. Preserve the project architecture:
   - Flutter mobile app
   - Riverpod state management
   - FastAPI backend
   - PostgreSQL database
   - deterministic scheduling rules
   - AI-assisted but user-confirmed actions

## Output format required from the AI in every step

For each step, the AI should respond using this exact structure:

```md
## Step Result
### What was implemented
- ...

### Files created/updated
- ...

### Commands to run
```bash
...
```

### Manual test
- ...

### Notes / next step
- ...
```

---

# 2) Purpose of this addendum

The original roadmap already covers the core product:

- repository setup
- backend foundation
- Flutter foundation
- authentication and onboarding
- tasks and projects
- dashboard and quick capture
- notes, habits, focus, prayer, journal
- notifications and basic scheduling
- AI MVP
- voice MVP
- analytics MVP
- adaptive scheduling and automation
- hardening, QA, release, and deployment

This addendum adds the missing implementation coverage for:

1. full account security completion: Google sign-in, Apple sign-in, email verification, password reset by email code, and password change
2. complete onboarding personalization based on language, location, prayer method, goals, wake/sleep time, and permissions
3. full screen hierarchy completion
4. Qibla, Ramadan mode, missed prayer tracking, dhikr reminders, and spiritual polish
5. Google Keep-style notes: rich editing, structure, tags, pinned notes, reminders, archive, voice notes, and photo/image support
6. competitive upgrades inspired by TickTick, Focus To-Do, Google Keep, and Notion
7. premium reminder system with snooze, recurrence, constant reminders, stale invalidation, and notification center
8. algorithm registry and explanation pack for academic and engineering clarity
9. premium UI/UX design system, logo integration, smooth transitions, and Codex design prompts
10. stunning product polish: accessibility, Arabic/RTL QA, haptics, UX writing, app-store assets, support screens, and user testing
11. offline caching and sync conflict handling
12. production monitoring and crash analytics
13. reminder lifecycle and stale reminder invalidation
14. data deletion, retention, and tombstone rules
15. AI and voice fallback safety rules
16. monetization and growth infrastructure
17. final acceptance gates and MVP lock rules

---

# 3) Addendum phase map

| Phase | Name | Main goal |
|---|---|---|
| 12A | Authentication & Account Security Completion | complete Google/Apple/email auth, email verification, and secure password recovery |
| 12B | Onboarding Personalization Completion | finish the first-launch personalization flow exactly as the product vision requires |
| 12X | Extended Hardening & Production Readiness | finish production-quality reliability rules |
| 13 | Screen Coverage Completion | ensure all documented screens exist and behave correctly |
| 14 | Spiritual Module Completion | add Qibla, Ramadan mode, and prayer polishing |
| 15 | Notes & Capture Completion | add Google Keep-style notes, tags, checklists, photos, voice notes, and linked notes |
| 15A | Competitive Feature Upgrade Pack | add loved features inspired by TickTick, Focus To-Do, Google Keep, and Notion without copying their branding |
| 15B | Premium Reminder System | build the final high-quality reminder engine |
| 15C | Algorithm Registry & Explanation Pack | document and expose the algorithms used in the app |
| 16A | Premium UI/UX Design System & Motion Pass | stop feature coding and design the app visually using Claude/Stitch/Codex prompts |
| 16B | Stunning Product Polish & App Store Readiness | make the app feel premium, trustworthy, accessible, and launch-ready |
| 16 | Offline Sync & Data Safety | implement offline cache, conflict rules, tombstones, and retention |
| 17 | Monitoring, Metrics & Quality Gates | add crash monitoring, product analytics, and release gates |
| 18 | Monetization & Growth Foundation | prepare freemium/subscription structure without overbuilding |
| 19 | Final Documentation-to-Implementation Audit | verify full software documentation and README coverage |

---

# 4) Phase 12A — Authentication & Account Security Completion

## Goal
Upgrade authentication from basic login/register into a production-ready account system.

## Why this phase exists
The original roadmap implements basic JWT authentication. The final app should support modern sign-in methods and safe account recovery before real users depend on it.

## Scope
- email/password registration
- sign in with Google
- sign in with Apple
- email verification
- password reset using email code
- password change while logged in
- secure token handling
- account provider linking rules
- auth error UX

## Deliverables
- users can register with email/password
- users must verify email before full access if enabled
- users can sign in with Google
- iOS-ready Apple sign-in architecture exists
- users can reset password using a short code sent by email
- users can change password from settings
- auth flows are tested manually

## Steps

### Step 12A.1 Extend auth provider model
Backend:
- add auth_provider support:
  - email
  - google
  - apple
- add provider_user_id field where needed
- prevent duplicate accounts for the same email unless explicit linking is implemented
- keep user ownership checks unchanged

Frontend:
- add provider-aware auth state

Manual test:
- create normal email user
- simulate Google user payload in development
- verify duplicate email is handled safely

---

### Step 12A.2 Add email verification flow
Backend:
- add email verification token/code table or fields
- generate short-lived verification code
- send verification email through configured mail provider
- verify code endpoint
- resend verification endpoint with rate limiting

Frontend:
- add Verify Email screen
- add resend code button
- add clear error/success states

Manual test:
- register new user
- receive/log verification code in development
- enter wrong code
- enter correct code
- verify account becomes active/verified

---

### Step 12A.3 Add password reset by email code
Backend:
- create request password reset endpoint
- generate short-lived numeric or alphanumeric code
- send reset code to email
- verify reset code endpoint
- set new password endpoint
- invalidate used/expired codes
- rate-limit repeated attempts

Frontend:
- Forgot Password screen asks for email
- Code Verification screen
- New Password screen
- success screen returning user to sign in

Manual test:
- request reset code
- enter wrong code
- enter expired code
- enter correct code
- set new password
- sign in using new password

---

### Step 12A.4 Add change password from settings
Backend:
- endpoint requires current password
- validate new password strength
- rotate tokens if required

Frontend:
- Change Password screen under Settings / Account
- current password field
- new password field
- confirm password field

Manual test:
- change password with wrong current password
- change password with mismatch confirmation
- change password successfully
- log out and sign in with new password

---

### Step 12A.5 Add Google sign-in integration
Frontend:
- add Google sign-in button
- obtain Google ID token safely
- send token to backend

Backend:
- verify Google token using official validation approach
- create user if first login
- return app JWT
- mark email verified if Google email is verified

Manual test:
- sign in with Google test account
- log out
- sign in again
- verify same account is used

---

### Step 12A.6 Add Apple sign-in architecture
Frontend:
- add Apple sign-in button only where platform supports it
- prepare iOS configuration notes

Backend:
- verify Apple identity token
- create/link account safely
- handle private relay email edge cases

Manual test:
- verify Apple button does not appear on unsupported platforms if needed
- verify backend contract is documented
- test with simulator or real iOS device when available

---

### Step 12A.7 Add auth UX polish and safety states
Frontend:
- loading states for auth buttons
- disabled state while submitting
- clear field-level validation
- friendly errors for:
  - invalid credentials
  - unverified email
  - expired code
  - provider mismatch
  - network failure

Manual test:
- test all failure states once
- confirm user never sees raw backend errors

## Done when
- email/password, Google, and Apple auth architecture are complete
- email verification works
- password reset by email code works
- password change works
- auth flows are clear, safe, and testable

## AI instruction for this phase
Do not weaken security for speed. Keep provider login, verification, and reset flows simple, explicit, and safe.

---

# 5) Phase 12B — Onboarding Personalization Completion

## Goal
Complete the first-launch onboarding flow so the app feels personalized immediately after installation.

## Why this phase exists
The product vision depends on personalization. Onboarding must configure language, location, prayer settings, goals, daily rhythm, permissions, default habits, and dashboard state.

## Scope
- language selection
- country/city selection
- prayer calculation method
- main goals
- wake/sleep schedule
- notification permission
- microphone permission
- location permission
- automatic dashboard setup
- default habits
- AI recommendation seed profile
- initial task environment

## Deliverables
- first-time user completes guided onboarding
- onboarding data is saved to backend and local cache
- returning user skips onboarding
- dashboard is personalized after onboarding
- default habits are created from selected goals
- prayer schedule is configured after location/prayer settings

## Steps

### Step 12B.1 Build onboarding data contract
Backend:
- define onboarding payload schema
- store language, country/city, timezone, prayer method, goals, wake time, sleep time, work/study windows, permission flags
- expose onboarding completion endpoint

Frontend:
- create onboarding state model
- preserve selections between onboarding screens

Manual test:
- select all onboarding values
- submit onboarding
- verify data persists after restart

---

### Step 12B.2 Implement exact onboarding screens
Frontend screens:
- Preferred Language: Arabic / English
- Country or City
- Prayer Calculation Method
- Main Goals: study / work / self improvement / fitness / spiritual growth
- Preferred Wake-up Time
- Preferred Sleep Time
- Notification Permission
- Microphone Permission
- Location Permission
- Onboarding Summary

Manual test:
- complete onboarding from fresh account
- skip optional permissions
- allow optional permissions
- verify flow still completes

---

### Step 12B.3 Auto-configure dashboard after onboarding
System should configure:
- daily dashboard widgets
- next prayer card
- task environment
- habit snapshot
- journal prompt
- AI plan card
- focus shortcut

Manual test:
- choose study + spiritual growth goals
- complete onboarding
- verify dashboard reflects these choices

---

### Step 12B.4 Auto-create default habits
Based on selected goals:
- study → daily study habit
- work → deep work habit
- self improvement → reading/reflection habit
- fitness → exercise / hydration habit
- spiritual growth → prayer tracking / Quran reading habit

Manual test:
- select different goal combinations
- verify correct default habits appear

---

### Step 12B.5 Seed AI recommendation profile
Backend:
- create user preference profile for AI recommendations
- store goal tags and daily rhythm
- avoid storing unnecessary sensitive data

Frontend:
- show personalized AI recommendation preview after onboarding

Manual test:
- complete onboarding with different goals
- verify AI prompt/profile data changes safely

## Done when
- onboarding personalizes dashboard, prayer schedule, default habits, AI suggestions, and initial task environment
- skipped permissions do not break the app
- all onboarding choices can be edited later from Settings

## AI instruction for this phase
Make onboarding useful, short, and recoverable. Users must be able to edit onboarding choices later.

---

# 6) Phase 12X — Extended Hardening & Production Readiness

## Goal
Extend the original Phase 12 after Step 12.10 to include the missing production-readiness rules from the full software documentation.

## Why this phase exists
The original Phase 12 covers general hardening, QA, deployment, backups, beta builds, and soft launch preparation. This extension adds the deeper operational safety rules needed before trusting the app with real users.

## Scope
- production monitoring hooks
- crash and ANR monitoring
- structured backend error logging
- reminder lifecycle cleanup
- stale reminder invalidation
- AI fallback verification
- voice fallback verification
- final beta readiness checklist

## Deliverables
- app crash monitoring connected
- backend errors logged safely
- stale reminders invalidated correctly
- low-confidence AI and voice actions require confirmation
- beta-readiness checklist exists

## Steps

### Step 12.11 Add structured backend error logging
Backend:
- add structured logging format
- avoid logging sensitive user data
- log request ID if available
- log exception type, endpoint, and safe context

Frontend:
- show user-friendly errors instead of raw backend errors

Manual test:
- trigger validation error
- trigger unauthorized request
- trigger server-side error in development
- confirm logs are useful and safe

---

### Step 12.12 Add mobile crash monitoring placeholder/integration
Frontend:
- add crash monitoring integration placeholder
- prepare Firebase Crashlytics or equivalent
- ensure release builds can report fatal crashes
- ensure debug mode does not spam production logs

Manual test:
- run app in debug
- confirm crash monitoring setup does not break app startup
- prepare release configuration notes

---

### Step 12.13 Add backend performance monitoring basics
Backend:
- add request timing middleware
- log slow API requests
- track common failure points:
  - auth errors
  - sync errors
  - AI service failures
  - notification scheduling failures

Manual test:
- call several endpoints
- confirm request duration appears in logs
- confirm slow request threshold works in development

---

### Step 12.14 Add reminder lifecycle cleanup rules
Backend and mobile:
- cancel task reminders when task is completed
- cancel task reminders when task is deleted
- update reminders when task due date/time changes
- cancel habit reminders when habit is archived/deleted
- update prayer reminders when prayer settings or location changes

Manual test:
- create task with reminder
- complete task before reminder time
- confirm reminder is cancelled
- edit task time
- confirm old reminder does not fire

---

### Step 12.15 Add stale reminder invalidation tests
Testing:
- test deleted task reminders
- test completed task reminders
- test changed due time reminders
- test changed prayer method/location reminders
- test app restart after scheduled reminders exist

Manual test:
- use local notification test mode
- schedule reminders in near future
- mutate the related entities
- verify stale notifications do not appear

---

### Step 12.16 Add AI fallback safety audit
Backend:
- verify low-confidence AI parse does not directly create important data silently
- verify unsupported AI intent returns manual fallback
- verify AI service failure does not crash quick capture

Frontend:
- show editable preview before creating parsed tasks
- show manual entry fallback when AI fails

Manual test:
- enter clear task text
- enter ambiguous task text
- disconnect AI provider or simulate failure
- confirm the app remains usable

---

### Step 12.17 Add voice fallback safety audit
Frontend:
- verify voice states exist:
  - idle
  - listening
  - processing
  - transcript preview
  - success
  - fail
- verify transcript is editable before committing write actions
- verify Arabic and English command previews work

Backend:
- verify unsupported voice intent returns safe fallback
- verify low-confidence intent requires confirmation

Manual test:
- speak English task command
- speak Arabic task command
- speak unclear command
- confirm preview and fallback behavior

---

### Step 12.18 Add beta-readiness checklist file
Create:

```text
docs/beta_readiness_checklist.md
```

Checklist must include:
- auth stable
- task CRUD stable
- prayer calculation stable
- prayer tracking stable
- notification invalidation working
- AI preview and fallback working
- voice preview and fallback working
- sync convergence has no blocker
- no major crash in core flows
- monitoring hooks enabled
- MVP scope controlled

## Done when
- all added hardening checks pass manually
- known critical safety failures are fixed
- beta checklist exists and is usable

## AI instruction for this phase
Do not add new feature complexity. Focus only on reliability, trust, and production-readiness rules.

---

# 5) Phase 13 — Screen Coverage Completion

## Goal
Ensure every screen and navigation behavior described in the software documentation exists in the Flutter app.

## Why this phase exists
The original roadmap creates the app shell and core modules, but the full documentation contains more detailed screen behavior and nested navigation. This phase ensures the app UI structure fully matches the documentation.

## Scope
- screen hierarchy audit
- missing placeholder screens
- nested navigation flows
- empty states
- loading states
- error states
- confirmation dialogs
- screen-level manual tests

## Deliverables
- all documented screens exist
- all major navigation routes work
- all screens have basic loading/empty/error states
- navigation does not trap the user

## Steps

### Step 13.1 Create screen coverage checklist
Create:

```text
docs/screen_coverage_checklist.md
```

Include these groups:
- Splash
- Welcome
- Sign Up
- Sign In
- Forgot Password
- Onboarding screens
- Home
- Notes
- Habits
- Journal
- Tasks
- Task Details
- Create/Edit Task
- Project Details
- Focus
- Active Focus Session
- Focus History
- Prayer
- Prayer History
- Quran Goal
- Qibla
- Ramadan Mode
- Profile
- Settings
- Notification Settings
- Analytics
- Language and Localization
- Prayer Settings

---

### Step 13.2 Add missing route definitions
Frontend:
- add missing named routes
- ensure route guards work for authenticated screens
- ensure onboarding screens cannot be skipped incorrectly
- ensure bottom navigation state is preserved where practical

Manual test:
- navigate to every screen from the app UI
- use Android back button
- switch tabs repeatedly
- confirm app state remains stable

---

### Step 13.3 Add missing placeholder screens before full implementation
Frontend:
- if a feature is not ready, add a clean placeholder screen
- placeholder must explain the feature briefly
- placeholder must not break navigation

Manual test:
- open each placeholder screen
- confirm no crash
- confirm back navigation works

---

### Step 13.4 Add consistent empty states
Frontend:
Add empty states for:
- no tasks
- no projects
- no notes
- no habits
- no journal entries
- no focus sessions
- no prayer history
- no analytics data

Manual test:
- use a fresh account
- verify each empty state appears correctly

---

### Step 13.5 Add consistent loading and error states
Frontend:
- reusable loading widget
- reusable error widget
- retry action where useful
- friendly error messages

Manual test:
- simulate loading
- simulate API error
- verify retry works where applicable

---

### Step 13.6 Add destructive action confirmations
Frontend:
Add confirmation dialogs for:
- delete task
- delete project
- delete note
- delete habit
- delete journal entry
- logout
- clear local cache
- delete account placeholder/future action

Manual test:
- trigger each destructive action
- cancel once
- confirm once
- verify correct behavior

## Done when
- every documented screen is represented in Flutter
- all main routes work
- no missing screen blocks implementation
- screen checklist is complete

## AI instruction for this phase
Implement screen completeness and navigation safety. Do not add deep business logic unless required for route testing.

---

# 6) Phase 14 — Spiritual Module Completion

## Goal
Complete the spiritual feature set beyond the basic prayer MVP.

## Why this phase exists
The original roadmap covers prayer times, prayer logs, and Quran goals. The full software documentation also requires Qibla direction, Ramadan support, prayer settings polish, and stronger spiritual flow integration.

## Scope
- Qibla screen
- Ramadan mode
- prayer settings polish
- prayer calculation review
- Quran progress polish
- spiritual dashboard cards

## Deliverables
- Qibla screen exists
- Ramadan mode exists
- prayer settings are editable
- Quran goal progress works clearly
- spiritual features feel first-class, not hidden

## Steps

### Step 14.1 Build Qibla screen UI
Frontend:
- create Qibla screen
- show compass placeholder if sensor integration is not ready
- show direction text
- show location permission guidance

Backend:
- no backend required for MVP unless location is server-stored

Manual test:
- open Qibla screen from Prayer
- deny location permission
- allow location permission
- confirm UI handles both states

---

### Step 14.2 Add Qibla calculation service placeholder
Frontend:
- create qibla direction service
- calculate bearing using user location and Kaaba coordinates
- prepare compass sensor integration if available

Manual test:
- use fixed Cairo coordinates
- confirm calculated bearing is returned
- confirm app does not crash without sensors

---

### Step 14.3 Build Ramadan Mode screen
Frontend:
- create Ramadan Mode screen
- show fasting status
- show Suhoor reminder setting
- show Iftar time from Maghrib
- show Ramadan goals placeholder

Backend:
- add Ramadan settings fields if needed:
  - suhoor_reminder_enabled
  - suhoor_reminder_minutes_before_fajr
  - ramadan_mode_enabled

Manual test:
- enable Ramadan mode
- check Iftar time displays as Maghrib
- set Suhoor reminder preference

---

### Step 14.4 Add Ramadan notification rules
Notification layer:
- schedule Suhoor reminder before Fajr
- schedule Iftar reminder at Maghrib
- cancel Ramadan reminders when Ramadan mode is disabled
- update reminders when prayer settings/location changes

Manual test:
- enable Ramadan mode
- schedule test reminders in near future
- disable Ramadan mode
- verify stale reminders are cancelled

---

### Step 14.5 Polish Prayer Settings screen
Frontend:
Prayer settings should allow:
- calculation method
- location selection/manual city
- reminder timing
- Athan sound toggle placeholder
- Ramadan mode toggle

Backend:
- persist settings in user_settings or prayer_settings table

Manual test:
- update prayer calculation method
- update reminder timing
- restart app
- confirm settings persist

---

### Step 14.6 Polish Quran Goal flow
Frontend:
- create/edit daily page target
- mark pages completed
- show daily progress
- show weekly summary placeholder

Backend:
- ensure Quran goal and progress records are user-owned
- add update endpoint if missing

Manual test:
- create Quran goal
- update progress
- verify progress appears on Prayer and Home if included

## Done when
- Prayer module includes prayer times, tracking, history, Quran goals, Qibla, Ramadan mode, and settings
- spiritual features are accessible from Prayer and visible in the daily flow
- reminder rules do not create stale spiritual notifications

## AI instruction for this phase
Keep the spiritual module practical and respectful. Build reliable MVP behavior before advanced spiritual personalization.

---

# 7) Phase 15 — Notes & Capture Completion

## Goal
Complete the notes and capture features required by the full software documentation and README.

## Why this phase exists
The original roadmap covers notes CRUD and search. The full product needs a stronger Google Keep-like note experience with structured editing, photos, checklists, reminders, tags, pinned notes, archive, voice notes, and task-linked notes.

## Scope
- note tags / labels
- note colors
- pinned notes
- archived notes
- note reminders
- note search improvement
- checklist notes
- rich structured note editor
- photo/image attachments
- voice note transcript support
- task-linked notes
- quick capture note classification
- future-ready OCR placeholder
- future-ready handwriting placeholder
- future-ready AI summary placeholder

## Deliverables
- notes support tags/labels
- notes support pinned and archived states
- notes support reminders
- notes support checklist-style content
- notes support photo/image attachments
- voice capture can become a note transcript
- notes can be linked to tasks where useful
- quick capture can create notes reliably

## Steps

### Step 15.1 Add note tags and labels
Backend:
- add note_tags support using either:
  - simple string array field, or
  - normalized note_tags table

Frontend:
- add tag input to note editor
- show tags in note list
- filter notes by tag

Manual test:
- create note with tags
- edit tags
- filter/search by tag

---

### Step 15.2 Add note color, pinned state, and archive
Backend:
- add color_key
- add is_pinned
- add archived_at

Frontend:
- allow note color selection
- allow pin/unpin
- allow archive/unarchive
- show pinned notes first

Manual test:
- pin note
- change color
- archive note
- verify archived note disappears from main list and appears in archive

---

### Step 15.3 Add checklist note support
Backend:
- choose simple MVP approach:
  - store checklist items as structured JSON, or
  - create note_checklist_items table

Frontend:
- allow note type:
  - text
  - checklist
- add checklist item toggle

Manual test:
- create checklist note
- mark item complete
- close and reopen note
- verify state persists

---

### Step 15.4 Add structured note editor
Frontend:
The editor should support:
- title
- body
- headings
- bullet lists
- numbered lists
- checklist blocks
- image blocks
- linked task block
- reminder chip
- tag chips

Backend:
- store either markdown + metadata or structured JSON blocks
- keep export path possible later

Manual test:
- create structured note with text, checklist, image, and tags
- edit it
- verify all content persists

---

### Step 15.5 Add photo/image attachments in notes
Backend:
- create note_attachments table or object storage reference
- fields:
  - note_id
  - file_url or local_path
  - file_type
  - file_size
  - created_at

Frontend:
- add image picker
- preview image inside note
- remove image
- handle upload failure gracefully

Manual test:
- add photo to note
- reopen note
- remove photo
- verify attachment state updates

---

### Step 15.6 Add note reminders
Backend:
- connect notes to unified reminder model

Frontend:
- add reminder button in note editor
- show reminder chip on note card

Manual test:
- create note reminder
- edit reminder time
- archive note
- verify reminder behavior follows reminder rules

---

### Step 15.7 Add voice note transcript support
Frontend:
- allow voice capture to create note transcript
- show transcript preview before saving
- allow user to edit transcript

Backend:
- save transcript as note content
- optional field:
  - source = voice

Manual test:
- record short English note
- record short Arabic note
- edit transcript
- save note

---

### Step 15.8 Add task-linked notes
Backend:
- allow optional task_id on notes, or create task_notes relation

Frontend:
- show linked notes inside Task Details
- allow creating a note from Task Details

Manual test:
- open task
- add linked note
- verify note appears in task details and Notes screen

---

### Step 15.9 Improve quick capture classification
Quick capture should support:
- task
- note
- reminder
- checklist
- journal entry
- unclear input requiring confirmation

Frontend:
- add confirmation bottom sheet
- allow user to choose type manually if unclear

Backend:
- keep simple deterministic classification before AI if AI unavailable

Manual test:
- type clear task
- type random idea/note
- type checklist-style input
- type ambiguous text
- verify confirmation flow

---

### Step 15.10 Add future-ready smart note placeholders
Add non-blocking placeholders for:
- OCR from images
- handwriting support
- AI note summary
- AI action extraction from note

Manual test:
- open smart note menu
- verify future features are clearly marked and do not break current note editing

## Done when
- notes match the full documented and README scope
- quick capture can create tasks, notes, reminders, checklists, and journal entries safely
- voice notes have preview/edit flow
- photo/image notes work
- notes are useful as part of the larger life system

## AI instruction for this phase
Do not turn notes into a complex Notion clone. Implement the documented MVP features cleanly, then add structured blocks only where they directly improve note-taking.

---

# 8A) Phase 15A — Competitive Feature Upgrade Pack

## Goal
Add the best missing product features inspired by loved patterns from TickTick, Focus To-Do, Google Keep, and Notion, while keeping Smart Life Planner original and focused.

## Why this phase exists
The README positions the app as an all-in-one alternative to task managers, note apps, focus timers, habit trackers, and prayer apps. This phase closes gaps that users expect from premium productivity tools.

## Scope
- calendar views
- Eisenhower matrix
- Kanban view
- timeline/light Gantt view
- drag-and-drop task ordering
- custom filters
- recurring rules polish
- location-based reminders placeholder
- time-zone aware planning
- task completion history
- Notion-lite structured blocks
- templates
- dashboard customization
- focus ambient sound placeholder
- focus streaks
- estimated Pomodoro count
- habit library
- missed prayer tracking
- dhikr reminders
- mood vs productivity insights
- productivity score
- context intelligence placeholders
- AI life coach placeholders

## Deliverables
- roadmap includes loved competitor-inspired features
- MVP-safe features are implemented or clearly deferred
- advanced features are represented as future-ready placeholders when too large
- no copied branding or direct cloning of competitors

## Steps

### Step 15A.1 Add task calendar views
Frontend:
- add Today / Week / Month agenda-style views
- show tasks, focus sessions, habits, and prayer anchors where useful

Backend:
- provide date-range task endpoint if missing

Manual test:
- create tasks across several dates
- switch Today / Week / Month views
- verify correct grouping

---

### Step 15A.2 Add Eisenhower Matrix view
Frontend:
- create matrix with four quadrants:
  - urgent + important
  - important + not urgent
  - urgent + not important
  - not urgent + not important

Backend/Algorithm:
- compute urgent from deadline proximity
- compute important from priority, goal link, or manual flag

Manual test:
- create tasks with different priorities and deadlines
- verify task placement in quadrants

---

### Step 15A.3 Add Kanban project view
Frontend:
- add project board with columns such as:
  - Inbox
  - Next
  - In Progress
  - Waiting
  - Done
- support drag-and-drop status movement if practical

Backend:
- add task status field if missing

Manual test:
- move task between columns
- restart app
- verify status persists

---

### Step 15A.4 Add timeline view for projects
Frontend:
- create lightweight timeline screen for project tasks
- show start date, due date, estimated duration
- support read-only first; drag adjustment can be future

Manual test:
- create project with multiple tasks
- open timeline
- verify order and dates appear correctly

---

### Step 15A.5 Add custom filters and smart lists
Frontend:
- add saved filters such as:
  - High priority this week
  - Overdue
  - Waiting For
  - No due date
  - Deep work tasks
  - Prayer-friendly tasks

Backend:
- expose filter parameters or local filtering layer

Manual test:
- create varied task set
- verify each filter returns expected tasks

---

### Step 15A.6 Add drag-and-drop task ordering
Frontend:
- allow manual order inside Today and project lists
- preserve manual_order field

Backend:
- store order index per list/project/day

Manual test:
- reorder tasks
- close/reopen app
- verify order persists

---

### Step 15A.7 Add task completion history
Backend:
- store task completion events or completed_at history
- support reopened tasks

Frontend:
- show completion history in task details or analytics

Manual test:
- complete task
- reopen task
- complete again
- verify history is correct

---

### Step 15A.8 Add Notion-lite structured note blocks
Frontend:
Support simple note blocks:
- heading
- paragraph
- checklist
- bullet list
- divider
- image block
- task link block

Backend:
- store structured note content as JSON safely

Manual test:
- create structured note
- reorder/edit blocks if supported
- verify content persists

---

### Step 15A.9 Add templates
Templates can include:
- daily plan
- study session
- weekly review
- project plan
- meeting notes
- habit reset
- Ramadan daily routine

Manual test:
- create note/task plan from template
- edit generated content
- save successfully

---

### Step 15A.10 Add dashboard customization
Frontend:
- allow users to show/hide/reorder dashboard widgets
- widgets:
  - top tasks
  - next prayer
  - habits
  - focus shortcut
  - journal prompt
  - productivity score
  - AI plan
  - Quran goal

Manual test:
- hide a widget
- reorder widgets
- restart app
- verify dashboard preference persists

---

### Step 15A.11 Add Focus To-Do inspired focus upgrades
Frontend:
- custom focus duration
- custom short break
- custom long break
- skip break
- continuous mode
- estimated Pomodoro count per task
- focus streak
- ambient sound placeholder
- distraction-free mode
- app blocking placeholder/future integration
- AI focus recommendation placeholder
- productivity prediction placeholder
- focus report summary

Manual test:
- create task with estimated Pomodoros
- start focus session
- skip break
- complete session
- verify report and streak update

---

### Step 15A.12 Add habit library and categories
Frontend:
- habit creation from templates:
  - study
  - reading
  - Quran
  - exercise
  - hydration
  - sleep
  - meditation/reflection

Backend:
- support habit category and frequency:
  - daily
  - weekly
  - custom

Manual test:
- create habit from library
- complete habit
- verify analytics/streak update

---

### Step 15A.13 Add spiritual upgrade placeholders
Add MVP or placeholders for:
- missed prayer tracking
- dhikr reminders
- fasting tracker
- taraweeh tracking
- Islamic calendar events
- masjid locator placeholder

Manual test:
- mark prayer missed
- add dhikr reminder
- enable fasting tracker placeholder

---

### Step 15A.14 Add context intelligence placeholders
Prepare fields and UI for:
- location context
- device context
- time context
- energy level
- weather-based suggestions

Manual test:
- set manual energy level
- verify recommendation explanation can reference it

---

### Step 15A.15 Add AI life coach placeholders
Frontend:
- Goal Roadmap screen placeholder
- Study Planner AI placeholder
- Weekly Life Review placeholder
- Motivation Engine placeholder
- AI Weekly Review screen
- long-term goal decomposition flow

Backend:
- no advanced autonomous coaching yet
- prepare safe endpoint contracts only if needed

Manual test:
- open placeholders
- verify they do not block MVP features

### Step 15A.16 Add GTD organization buckets
Frontend:
- add task/list views for:
  - Inbox
  - Next Actions
  - Projects
  - Waiting For
  - Someday
  - Calendar

Backend:
- add task bucket/status support if not already covered
- allow AI clarification to suggest the correct GTD bucket

Manual test:
- create task in Inbox
- move task to Next Actions
- mark task as Waiting For
- move future idea to Someday
- verify calendar/time-specific tasks appear in Calendar view

---

### Step 15A.17 Add voice future capability placeholders
Frontend:
- voice journaling entry point
- voice navigation placeholder
- voice summary placeholder

Backend:
- no full conversational assistant yet
- add safe endpoint contracts only when needed

Manual test:
- open voice actions menu
- verify future capabilities are visible as planned but do not break MVP voice task creation

## Done when
- the app contains the most loved productivity patterns without becoming messy
- MVP-safe items are usable
- large advanced items are documented and future-ready
- GTD buckets from the README are represented
- voice journaling/navigation/summaries are at least future-ready
- the app feels more competitive against major productivity tools

## AI instruction for this phase
Do not clone competitor apps. Use their best ideas as inspiration and adapt them to Smart Life Planner’s AI + spiritual + life operating system identity.

---

# 8B) Phase 15B — Premium Reminder System

## Goal
Build a reminder system that feels reliable, flexible, and premium.

## Why this phase exists
Reminders are core to trust. A productivity app fails if reminders are late, duplicated, stale, annoying, or hard to control.

## Scope
- task reminders
- recurring task reminders
- habit reminders
- prayer notifications
- Quran reminders
- focus prompts
- bedtime reminders
- AI suggestion reminders
- note reminders
- location-based reminder placeholder
- snooze
- persistent/constant reminders
- quiet hours
- timezone/DST safety
- stale reminder invalidation
- reminder analytics

## Deliverables
- all reminder types use one clear reminder model
- users can snooze and reschedule reminders
- completed/deleted items cancel reminders
- recurring reminders expand safely
- reminder behavior respects notification settings
- reminder system is manually testable

## Steps

### Step 15B.1 Create unified reminder model
Backend:
Reminder fields:
- id
- user_id
- target_type
- target_id
- reminder_type
- scheduled_at
- recurrence_rule
- timezone
- status
- snooze_until
- channel
- priority
- created_at
- updated_at
- cancelled_at

Frontend:
- shared reminder UI component

Manual test:
- create reminders for task, habit, note, Quran goal
- verify all use same model

---

### Step 15B.2 Add reminder channels and preferences
Channels:
- push/local notification
- in-app notification center
- email placeholder/future

Preferences:
- enable/disable by type
- quiet hours
- prayer notification timing
- bedtime reminder timing
- focus prompt timing

Manual test:
- disable habit reminders
- verify habit reminders do not schedule
- keep prayer reminders enabled

---

### Step 15B.3 Add smart task reminder presets
Presets:
- at due time
- 10 minutes before
- 1 hour before
- 1 day before
- custom
- recurring custom rules

Manual test:
- create task due tomorrow
- add multiple reminders
- edit due date
- verify reminders update

---

### Step 15B.4 Add snooze and reschedule actions
Frontend:
Notification actions:
- Mark done
- Snooze 10 minutes
- Snooze 1 hour
- Reschedule
- Open task

Manual test:
- trigger test notification
- snooze
- verify new reminder appears

---

### Step 15B.5 Add persistent/constant reminder option
For important tasks only:
- repeat notification until completed or dismissed
- limit frequency to avoid abuse
- allow user to disable constant reminders globally

Manual test:
- create high-priority task with constant reminder
- ignore first notification
- verify follow-up appears according to safe rules
- complete task
- verify reminder stops

---

### Step 15B.6 Add stale reminder invalidation engine
Cancel or update reminders when:
- task completed
- task deleted
- task due time changed
- habit deleted/paused
- prayer method/location changed
- Quran goal disabled
- note archived/deleted
- user logs out
- timezone changes

Manual test:
- schedule reminder
- mutate linked item
- verify stale notification does not fire

---

### Step 15B.7 Add notification center
Frontend:
- in-app notification inbox
- show recent reminders
- show missed reminders
- allow clearing old notifications

Manual test:
- trigger reminder
- open notification center
- clear notification

---

### Step 15B.8 Add reminder QA checklist
Create:

```text
docs/reminder_system_qa.md
```

Include tests for:
- task reminders
- recurring reminders
- habit reminders
- prayer reminders
- Quran reminders
- bedtime reminders
- snooze
- stale invalidation
- timezone changes
- offline scheduling
- permission denied state

## Done when
- reminder behavior is consistent, predictable, and easy to test
- users can control reminders without being overwhelmed
- stale/duplicate notifications are eliminated as much as possible

## AI instruction for this phase
Prioritize reliability over cleverness. A simple reminder that works is better than a smart reminder that fails.

---

# 8C) Phase 15C — Algorithm Registry & Explanation Pack

## Goal
Document every algorithm used in Smart Life Planner and expose important algorithm decisions clearly for development, testing, and academic explanation.

## Why this phase exists
The project uses AI, scheduling, recommendations, reminders, analytics, prayer-aware planning, and sync. Claude must clearly state what algorithms are used and where they are implemented.

## Scope
- algorithm registry document
- algorithm-to-feature mapping
- code comments for core algorithms
- explainability fields in API responses
- academic/report-ready explanations
- test cases for deterministic algorithms

## Deliverables
- `docs/algorithm_registry.md`
- algorithm explanations for core features
- API responses include explanation metadata where useful
- deterministic algorithms have manual or unit tests

## Steps

### Step 15C.1 Create algorithm registry
Create:

```text
docs/algorithm_registry.md
```

Include these algorithms:
- NLP task parsing
- intent classification
- priority scoring
- urgency scoring
- Eisenhower classification
- greedy daily scheduling
- interval conflict detection
- dependency eligibility / topological readiness
- overload detection
- future-only replanning
- recurrence expansion
- reminder invalidation
- habit streak calculation
- habit consistency scoring
- productivity score calculation
- focus score calculation
- time estimation
- burnout risk heuristic
- mood vs productivity correlation
- context recommendation scoring
- Qibla bearing calculation
- prayer-aware schedule blocking
- sync conflict resolution using Last Write Wins
- tombstone-based deletion protection

---

### Step 15C.2 Add algorithm-to-feature mapping
For each algorithm document:
- feature using it
- input data
- output data
- deterministic or AI-assisted
- where code lives
- limitations
- manual test method

Manual test:
- pick 5 features
- verify each has algorithm mapping

---

### Step 15C.3 Add scoring formula documentation
Document formulas for:
- priority score
- urgency score
- next best action score
- productivity score
- focus score
- overload risk score

Example:

```text
Next Best Action Score =
(priority_weight × priority_score)
+ (urgency_weight × urgency_score)
+ (dependency_weight × readiness_score)
+ (energy_weight × energy_match_score)
- (friction_weight × task_friction)
```

Manual test:
- create tasks with different values
- verify ranking explanation matches score logic

---

### Step 15C.4 Add explainability metadata to AI/scheduler responses
Backend responses should include:
- selected item
- score
- top reasons
- rejected/conflicting items when useful
- confidence
- fallback flag

Manual test:
- call next-action endpoint
- verify response explains why that task was selected

---

### Step 15C.5 Add algorithm test checklist
Create:

```text
docs/algorithm_test_checklist.md
```

Include tests for:
- urgent high-priority task ranking
- blocked task exclusion
- prayer time conflict avoidance
- overload detection
- future-only replanning
- habit streak reset
- recurring reminder expansion
- timezone change handling

## Done when
- Claude can explain the algorithms used in the app
- implementation decisions are academically presentable
- core algorithms are deterministic, testable, and documented

## AI instruction for this phase
Do not hide logic inside vague AI calls. Every important decision must be explainable through a documented algorithm or explicit AI-assisted fallback.

---

# 8D) Phase 16A — Premium UI/UX Design System & Motion Pass

## Goal
Pause feature implementation and convert the working app into a polished, premium product experience.

## Best timing
This phase should happen after:
- authentication/account flows exist
- onboarding exists
- core screens exist
- major feature screens exist
- notes/prayer/focus/tasks/dashboard flows are represented

It should happen before:
- final offline sync hardening
- production monitoring
- monetization polish
- final audit

## Why this phase exists
The app should not only work; it should feel premium. This phase lets the developer use Claude, Google Stitch, or another design assistant to create the visual direction, then use Codex prompts to connect the selected design to existing Flutter files.

## Scope
- stop feature coding temporarily
- audit all existing screens/widgets/buttons
- create visual design brief
- choose colors
- choose typography
- choose spacing system
- choose icon style
- add logo
- design dashboard and main modules
- design transitions and animations
- create reusable Flutter design system
- generate Codex prompts for applying design to code
- premium motion/animation pass

## Deliverables
- design brief
- design tokens
- logo integration plan
- screen-by-screen design requirements
- widget inventory
- animation/motion spec
- Codex prompt pack
- Flutter theme update
- reusable UI components

## Steps

### Step 16A.1 Freeze feature implementation and create UI inventory
Create:

```text
docs/ui_inventory.md
```

List:
- all screens
- all widgets
- all buttons
- all cards
- all forms
- all dialogs
- all bottom sheets
- all navigation patterns
- empty states
- loading states
- error states

Manual test:
- open app
- compare all screens against inventory

---

### Step 16A.2 Create design brief for Claude / Google Stitch
Create:

```text
docs/design_brief_for_claude_or_stitch.md
```

Include:
- app identity
- target users
- desired feeling: calm, intelligent, premium, spiritual, focused
- core screens
- required widgets
- Arabic/English support
- dark/light mode
- accessibility needs
- logo placement
- competitor inspiration without copying
- preferred design direction

Manual test:
- paste brief into design tool
- verify generated design covers all major screens

---

### Step 16A.3 Choose design system tokens
Create:

```text
docs/design_tokens.md
```

Define:
- primary color
- secondary color
- accent color
- background colors
- surface colors
- success/warning/error colors
- typography scale
- font family
- border radius
- shadows
- spacing scale
- icon style
- card style

Manual test:
- apply tokens to one screen
- verify visual direction works

---

### Step 16A.4 Add logo integration plan
Create:

```text
docs/logo_integration_plan.md
```

Include:
- splash screen logo
- welcome screen logo
- app icon requirements
- in-app small logo placement
- adaptive icon notes for Android
- future iOS icon notes

Manual test:
- place temporary logo asset
- verify it appears correctly on splash/welcome/profile

---

### Step 16A.5 Create Codex prompt pack for design integration
Create:

```text
docs/codex_design_integration_prompts.md
```

Prompts should cover:
- applying Flutter theme tokens
- redesigning Home dashboard
- redesigning Tasks screens
- redesigning Prayer screen
- redesigning Focus screen
- redesigning Notes editor
- redesigning Onboarding flow
- adding premium bottom navigation
- adding smooth page transitions
- adding micro-interactions
- adding loading skeletons
- adding empty-state illustrations/placeholders
- adding logo assets safely

Each prompt must tell Codex:
- do not break existing logic
- preserve routes/providers/API calls
- update only UI files unless necessary
- keep Arabic/RTL support
- test after each screen

---

### Step 16A.6 Add premium transitions and animations
Frontend:
- smooth route transitions
- animated bottom navigation indicator
- card entrance animations
- button press feedback
- task completion animation
- focus start/end animation
- prayer completion feedback
- skeleton loading states

Manual test:
- navigate between tabs
- complete task
- start/end focus session
- mark prayer complete
- verify animations feel smooth and not distracting

---

### Step 16A.7 Create final UI acceptance checklist
Create:

```text
docs/ui_acceptance_checklist.md
```

Checklist:
- all screens use theme tokens
- no random colors remain
- typography is consistent
- spacing is consistent
- Arabic/RTL layout is not broken
- buttons are accessible
- dark/light mode works
- transitions are smooth
- logo appears correctly
- loading/empty/error states look premium

## Done when
- the app has a consistent premium visual identity
- design is documented
- Codex prompts exist for applying design safely
- animations improve experience without slowing the app
- the logo is integrated cleanly

## AI instruction for this phase
Pause feature expansion. Focus on making the existing app beautiful, coherent, accessible, and premium.

---

# 8E) Phase 16B — Stunning Product Polish & App Store Readiness

## Goal
Make Smart Life Planner feel like a premium, polished, trustworthy app that users would actually love using every day.

## Why this phase exists
A strong feature list is not enough. To feel stunning, the app needs excellent micro-interactions, accessibility, onboarding copy, empty states, performance, Arabic/English polish, haptics, app-store assets, and real user testing.

## Scope
- final UX writing
- premium empty states
- illustrations/placeholders
- haptics
- sound feedback where appropriate
- accessibility pass
- Arabic/RTL quality pass
- responsive layout pass
- app icon and splash polish
- app store screenshots
- onboarding copy polish
- permission explanation polish
- performance feel pass
- real-user testing checklist
- support and feedback entry points
- privacy/trust screens

## Deliverables
- polished UX copy
- premium empty/loading/error states
- haptic feedback map
- accessibility checklist
- Arabic/RTL checklist
- app-store visual checklist
- real-user testing script
- support/feedback screen
- privacy/trust screen

## Steps

### Step 16B.1 Add UX writing and microcopy pass
Create:

```text
docs/ux_writing_microcopy.md
```

Cover:
- onboarding messages
- permission explanations
- empty states
- AI confirmation copy
- error messages
- success messages
- prayer/spiritual wording
- reminder wording
- premium feature wording

Manual test:
- read every important screen aloud
- remove robotic wording
- make messages short, calm, and helpful

---

### Step 16B.2 Add premium empty/loading/error states
Frontend:
- replace plain empty screens with helpful illustrated states or icon cards
- add skeleton loading for dashboard, tasks, notes, prayer, analytics
- add friendly retry states

Manual test:
- fresh account empty state
- slow network state
- failed API state
- offline state

---

### Step 16B.3 Add haptics and subtle feedback map
Create:

```text
docs/haptics_feedback_map.md
```

Add haptics for:
- task completed
- focus session started
- focus session completed
- prayer marked complete
- habit marked complete
- reminder snoozed
- error/invalid action

Manual test:
- test on real Android device
- verify feedback feels subtle, not annoying

---

### Step 16B.4 Add accessibility pass
Create:

```text
docs/accessibility_checklist.md
```

Check:
- touch target sizes
- text contrast
- scalable text
- screen reader labels
- icon buttons have labels
- forms have clear validation
- color is not the only signal
- prayer/focus/timer screens are readable

Manual test:
- increase system font size
- use screen reader basics
- check main flows with one hand

---

### Step 16B.5 Add Arabic/RTL quality pass
Create:

```text
docs/arabic_rtl_quality_checklist.md
```

Check:
- Arabic layout direction
- mixed Arabic/English text
- numbers and time formatting
- prayer names
- onboarding language switching
- voice command examples
- button alignment
- bottom navigation labels

Manual test:
- switch to Arabic
- complete onboarding
- create Arabic task
- create Arabic voice note
- open Prayer and Dashboard screens

---

### Step 16B.6 Add responsive and device polish pass
Frontend:
- test small phones
- test large phones
- test tablets if supported
- prevent overflow
- make bottom sheets scrollable
- ensure keyboard does not cover forms

Manual test:
- run on multiple emulator sizes
- test dark/light mode
- test landscape only if supported

---

### Step 16B.7 Add app icon, splash, and logo polish
Frontend/assets:
- integrate final logo
- create Android adaptive icon
- polish splash screen
- ensure logo looks good in dark/light modes

Manual test:
- install app on device
- check launcher icon
- open splash screen
- check welcome screen logo

---

### Step 16B.8 Add app store asset plan
Create:

```text
docs/app_store_assets_plan.md
```

Include:
- app name
- short description
- full description
- feature bullets
- screenshots list
- cover image plan
- privacy policy link placeholder
- support email placeholder
- keywords
- target audience notes

Manual test:
- verify screenshots cover onboarding, dashboard, tasks, focus, prayer, notes, analytics, AI planner

---

### Step 16B.9 Add real-user testing script
Create:

```text
docs/user_testing_script.md
```

Test tasks:
- create account
- complete onboarding
- add task manually
- add task by voice
- create note with photo
- start focus session
- mark prayer complete
- create habit
- use reminder
- generate daily plan
- change theme/language

Collect:
- confusion points
- slow screens
- ugly screens
- missing feedback
- most loved feature
- least useful feature

Manual test:
- run with at least 3–5 testers before public beta

---

### Step 16B.10 Add support, feedback, and trust screens
Frontend:
- Help & Support screen
- Send Feedback screen
- Privacy & Data screen
- About app screen

Backend:
- feedback endpoint or email fallback

Manual test:
- open support screen
- submit test feedback
- verify user sees confirmation

## Done when
- app feels polished, not just functional
- Arabic and English both feel professional
- main flows feel smooth on a real device
- app-store assets are planned
- real-user testing checklist exists
- users have clear support and trust screens

## AI instruction for this phase
Do not add big new features here. Polish what already exists until the app feels premium, calm, fast, trustworthy, and emotionally satisfying.

---

# 9) Phase 16 — Offline Sync & Data Safety

## Goal
Implement the missing offline support, sync conflict handling, deletion safety, and data retention rules.

## Why this phase exists
The full software documentation requires essential offline use and safe synchronization. The original roadmap mentions local caching but does not fully define sync conflict handling and deletion protection.

## Scope
- local cache for core entities
- offline create/update queue
- last-write-wins conflict handling
- tombstone delete protection
- sync failure states
- account deletion placeholder/rules
- data retention policy implementation notes

## Deliverables
- app can perform essential actions offline
- offline changes sync when internet returns
- conflicts use defined rules
- deleted items do not reappear due to stale sync
- retention/delete behavior is documented and partially implemented

## Steps

### Step 16.1 Define sync-supported entities
Create:

```text
docs/sync_entities.md
```

Include MVP sync entities:
- tasks
- projects
- subtasks
- notes
- habits
- habit logs
- journal entries
- prayer logs
- focus sessions
- user settings

Exclude initially:
- complex analytics snapshots
- AI suggestions history if not needed
- temporary voice transcripts after confirmation

---

### Step 16.2 Add local cache models
Frontend:
- add Hive/SQLite local models for core entities
- include:
  - id
  - server_id if needed
  - user_id
  - created_at
  - updated_at
  - deleted_at
  - sync_status

Sync statuses:
- synced
- pending_create
- pending_update
- pending_delete
- failed

Manual test:
- create local record
- verify it exists in local storage
- restart app
- verify record still appears

---

### Step 16.3 Implement offline create/update queue
Frontend:
- when offline, save changes locally
- mark records as pending
- show small sync status indicator where appropriate
- avoid blocking the user from basic actions

Manual test:
- turn off internet
- create task
- edit note
- mark habit complete
- confirm actions work locally

---

### Step 16.4 Implement sync worker
Frontend:
- detect connectivity restoration
- push pending changes to backend
- fetch updated server state
- update local cache

Backend:
- ensure endpoints support updated_at fields
- ensure ownership checks remain strict

Manual test:
- create offline task
- restore internet
- verify task syncs to backend
- log out/in if needed
- confirm task still exists

---

### Step 16.5 Implement Last Write Wins conflict rule
Conflict rule:
- compare updated_at timestamps
- newest valid update wins
- never overwrite a local pending change silently without applying the defined rule

Manual test:
- simulate server version newer than local
- simulate local version newer than server
- verify correct winner

---

### Step 16.6 Implement tombstone-based delete protection
Backend:
- support deleted_at for soft deletion where needed
- avoid physical deletion immediately for sync-supported records

Frontend:
- pending_delete records remain tombstones until backend confirms
- deleted server records remove/hide local copies

Manual test:
- create item on device
- delete it offline
- sync later
- verify it does not reappear

---

### Step 16.7 Add sync error recovery UI
Frontend:
- show failed sync indicator
- allow retry sync
- show non-scary message
- keep data editable if safe

Manual test:
- force backend failure
- make offline change
- attempt sync
- verify failed state and retry behavior

---

### Step 16.8 Add account deletion and retention placeholder
Backend:
- create account deletion request endpoint placeholder or implementation
- define retention behavior in docs
- ensure deletion requires authenticated user

Frontend:
- add Delete Account screen placeholder under Settings
- show warning and confirmation flow

Manual test:
- open delete account flow
- cancel
- verify no data removed

---

### Step 16.9 Add cloud backup and restore flow
Backend:
- define backup/export endpoint or backup process contract
- ensure user-owned data can be restored safely
- document what data is included in backup

Frontend:
- add Backup & Restore screen under Settings
- show last sync / last backup status
- add Restore Data placeholder or controlled restore flow

Manual test:
- trigger backup/export in development if implemented
- restore test data if implementation exists
- verify restored records do not duplicate existing synced records

## Done when
- essential app flows work offline
- core records sync safely
- deletion does not cause ghost records
- conflicts follow Last Write Wins in MVP
- backup and restore behavior is documented and future-ready
- user sees clear sync status when needed

## AI instruction for this phase
Keep sync simple. Use Last Write Wins for MVP and avoid complex merge logic unless explicitly required.

---

# 9) Phase 17 — Monitoring, Metrics & Quality Gates

## Goal
Add product-level analytics, production monitoring, and measurable release gates.

## Why this phase exists
The full documentation includes observability, quality targets, product metrics, growth metrics, engagement metrics, and beta readiness gates. This phase turns those into implementation tasks.

## Scope
- crash monitoring
- performance monitoring
- product analytics events
- release quality dashboard placeholder
- acceptance criteria per module
- beta gates
- MVP lock rules

## Deliverables
- key app events are tracked
- crashes and performance can be monitored
- module acceptance checklist exists
- MVP lock rules are documented

## Steps

### Step 17.1 Add product analytics event plan
Create:

```text
docs/product_analytics_events.md
```

Track events such as:
- sign_up_completed
- onboarding_completed
- task_created
- task_completed
- quick_capture_used
- ai_parse_accepted
- ai_parse_edited
- voice_command_started
- voice_command_confirmed
- focus_session_completed
- prayer_marked_complete
- habit_marked_complete
- note_created
- daily_plan_generated
- overload_warning_shown

---

### Step 17.2 Add analytics service wrapper
Frontend:
- create analytics service abstraction
- support no-op implementation for development
- prepare Firebase Analytics or equivalent

Manual test:
- trigger events in debug
- confirm events are printed/logged in development

---

### Step 17.3 Add backend metrics basics
Backend:
- track basic request counts/logs
- track error counts by endpoint
- track AI service failures
- track sync failures
- track notification scheduling errors

Manual test:
- trigger normal requests
- trigger failed requests
- inspect logs

---

### Step 17.4 Add module acceptance checklist
Create:

```text
docs/module_acceptance_checklist.md
```

Include acceptance criteria for:
- authentication
- onboarding
- dashboard
- tasks/projects
- notes
- habits
- focus
- prayer/Quran/Qibla/Ramadan
- notifications
- AI parsing
- voice commands
- analytics
- adaptive scheduling
- offline sync
- settings/profile

---

### Step 17.5 Add MVP lock rules document
Create:

```text
docs/mvp_lock_rules.md
```

MVP must include:
- authentication
- task CRUD and projects
- prayer times and prayer tracking
- quick AI task parsing
- dependency-aware next action
- overload-aware daily planning
- voice capture with preview/confirmation
- essential reminders
- dashboard overview

MVP must not expand into:
- advanced multi-day optimization
- full AI coaching ecosystem
- complex mood-productivity correlation engine
- customization marketplace
- aggressive AI nudging
- team collaboration features

---

### Step 17.6 Add final beta gate validation
Create:

```text
docs/final_beta_gate.md
```

The app is beta-ready only if:
- core auth flow is stable
- task CRUD is stable
- prayer calculation and tracking are stable
- notification invalidation rules work
- voice preview and confirmation work
- AI fallback to manual entry works
- sync convergence has no known blocker
- no major crash pattern exists in core flows
- production monitoring hooks are enabled
- MVP scope remains controlled

## Done when
- product metrics are defined
- analytics wrapper exists
- monitoring hooks exist
- beta gates are explicit
- MVP scope is protected

## AI instruction for this phase
Do not over-collect sensitive personal data. Track only useful product and quality events.

---

# 10) Phase 18 — Monetization & Growth Foundation

## Goal
Prepare the product for future freemium/subscription monetization without blocking the MVP.

## Why this phase exists
The full software documentation includes monetization, growth loops, subscription conversion, revenue metrics, and future startup potential. The original coding roadmap does not include implementation preparation for this.

## Scope
- premium feature flags
- subscription plan model placeholder
- paywall placeholder
- growth/share feature placeholder
- revenue analytics placeholders
- app store readiness notes

## Deliverables
- backend can represent free vs premium users later
- frontend can hide/show premium features later
- no payment provider is required for MVP unless explicitly chosen
- growth and monetization plan is technically prepared

## Steps

### Step 18.1 Add feature flag model
Backend:
- add feature_flags or app_config service if needed
- support user capability checks

Frontend:
- add feature access helper
- allow UI to check if feature is available

Feature examples:
- advanced_ai_planning
- voice_commands_extended
- advanced_analytics
- unlimited_projects
- premium_themes

Manual test:
- set feature enabled/disabled
- verify UI responds correctly

---

### Step 18.2 Add subscription status fields
Backend:
Add to user/account model or separate subscription table:
- plan_type: free / premium / student / lifetime
- subscription_status: inactive / active / canceled / trialing
- subscription_expires_at

Manual test:
- create free user
- update test user to premium manually
- verify backend returns plan info

---

### Step 18.3 Add paywall placeholder screen
Frontend:
- create Premium screen
- show planned premium benefits
- no real payment required yet
- include safe message: premium features coming soon

Manual test:
- open Premium screen from Profile
- verify screen does not block core MVP features

---

### Step 18.4 Add premium-gated UI placeholders
Frontend:
- visually mark future premium features without breaking UX
- do not lock essential MVP features

Possible premium future features:
- advanced analytics
- extended AI planning
- advanced voice assistant
- deep behavior insights
- unlimited history export

Manual test:
- free user sees locked placeholder
- premium test user sees enabled placeholder if implemented

---

### Step 18.5 Add share/growth placeholder
Frontend:
- add optional share progress card placeholder
- allow user to share productivity summary in future
- no social posting required in MVP

Manual test:
- open share placeholder
- confirm it does not expose private data accidentally

---

### Step 18.6 Add revenue metrics placeholders
Analytics:
Prepare event names:
- premium_screen_viewed
- premium_cta_clicked
- trial_started
- subscription_started
- subscription_cancelled

Manual test:
- click premium CTA in debug
- verify event is logged by analytics wrapper

## Done when
- monetization is technically prepared
- no MVP-critical flow depends on payments
- free users can still use the core product
- premium expansion can be added later safely

## AI instruction for this phase
Do not integrate real payments yet unless specifically requested. Build clean placeholders and feature gates only.

---

# 11) Phase 19 — Final Documentation-to-Implementation Audit

## Goal
Verify that the implemented product and roadmap fully cover the software documentation.

## Why this phase exists
The project is large. Without a final audit, some documented features, edge cases, or quality rules may remain unimplemented or untested.

## Scope
- functional requirements coverage
- non-functional requirements coverage
- screen coverage
- API coverage
- database coverage
- AI coverage
- voice coverage
- notification coverage
- sync coverage
- security coverage
- monetization coverage
- release readiness coverage

## Deliverables
- final coverage matrix
- missing items list
- deferred items list
- known limitations list
- final MVP readiness decision

## Steps

### Step 19.1 Create functional requirement coverage matrix
Create:

```text
docs/final_functional_coverage_matrix.md
```

Columns:
- Requirement ID
- Requirement description
- Implemented yes/no/partial
- Backend files
- Frontend files
- Manual test status
- Notes

---

### Step 19.2 Create non-functional requirement coverage matrix
Create:

```text
docs/final_nfr_coverage_matrix.md
```

Cover:
- performance
- security
- privacy
- maintainability
- localization
- offline support
- monitoring
- scalability
- usability

---

### Step 19.3 Create API coverage audit
Create:

```text
docs/final_api_coverage_audit.md
```

Check APIs for:
- auth
- users/settings
- tasks/projects/subtasks
- notes
- habits/logs
- focus sessions
- prayer/logs/settings
- Quran goals
- journal
- notifications
- AI
- voice
- analytics
- schedules/automation
- sync

---

### Step 19.4 Create database coverage audit
Create:

```text
docs/final_database_coverage_audit.md
```

Check tables/entities for:
- users
- user_settings
- projects
- tasks
- subtasks
- task_dependencies
- notes
- note tags/checklists if implemented
- habits
- habit_logs
- focus_sessions
- prayer_logs
- prayer_settings
- quran_goals
- journal_entries
- notifications/reminders
- daily_schedules
- schedule_blocks
- automation_events
- automation_actions
- analytics_snapshots if used
- subscription/feature flags if used

---

### Step 19.5 Create deferred scope list
Create:

```text
docs/deferred_scope.md
```

Separate items into:
- deferred after MVP
- future premium features
- future research-grade features
- intentionally excluded features

Examples:
- full AI coaching ecosystem
- team collaboration
- advanced multi-device merge UI
- marketplace/customization
- full desktop/web dashboard

---

### Step 19.6 Final MVP readiness decision
Create:

```text
docs/final_mvp_readiness_decision.md
```

Include:
- ready / not ready decision
- critical blockers
- non-critical known issues
- final manual test summary
- recommended release type:
  - internal MVP
  - closed beta
  - public beta
  - stable release

## Done when
- every major documentation item is marked implemented, partial, or deferred
- no hidden critical requirement remains
- the team knows whether the app is MVP-ready

## AI instruction for this phase
Be strict and honest. Do not claim a feature is complete unless it exists, runs, and has been manually tested.

---

# 12) Final execution order for Claude

Use this exact continuation order after the original roadmap:

```text
Continue from the original roadmap after Phase 12, Step 12.10.
Start with Addendum Phase 12A, Step 12A.1 only.
Do not skip ahead.
At each step:
1) implement only that step
2) show files created/changed
3) show commands to run
4) explain how I test it manually
5) stop and wait for my confirmation before moving to the next step
```

Then execute:

1. Phase 12A — Authentication & Account Security Completion
2. Phase 12B — Onboarding Personalization Completion
3. Phase 12X — Extended Hardening & Production Readiness
4. Phase 13 — Screen Coverage Completion
5. Phase 14 — Spiritual Module Completion
6. Phase 15 — Notes & Capture Completion
7. Phase 15A — Competitive Feature Upgrade Pack
8. Phase 15B — Premium Reminder System
9. Phase 15C — Algorithm Registry & Explanation Pack
10. Phase 16A — Premium UI/UX Design System & Motion Pass
11. Phase 16B — Stunning Product Polish & App Store Readiness
12. Phase 16 — Offline Sync & Data Safety
13. Phase 17 — Monitoring, Metrics & Quality Gates
14. Phase 18 — Monetization & Growth Foundation
15. Phase 19 — Final Documentation-to-Implementation Audit

Recommended Claude start prompt:

```text
You are helping me continue Smart Life Planner after the original AI Coding Roadmap.
Use the Roadmap Coverage Addendum strictly.
Start with Phase 12A, Step 12A.1 only.
Do not skip ahead.
Do not redesign architecture unless necessary.
At the end of every step, show:
- what was implemented
- files created/updated
- commands to run
- manual test steps
- what remains
Then stop and wait for my confirmation.
```

---

# 13) Final note

This addendum does not replace the original roadmap.

It exists to make the roadmap fully aligned with the complete software documentation by adding the missing implementation coverage for:

- final UI coverage
- spiritual feature completeness
- advanced capture completeness
- offline reliability
- sync safety
- deletion safety
- monitoring
- product metrics
- monetization preparation
- final acceptance gates

The final engineering principle remains:

> AI may assist the system, but deterministic product rules must protect the user.

