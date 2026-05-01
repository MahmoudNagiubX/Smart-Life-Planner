# Smart Life Planner — AI Coding Execution Roadmap

This file is the **implementation roadmap** for building Smart Life Planner step by step with an AI coding assistant.

It is written to be used as an **execution guide**, not just as a planning document.

---

# 1) How the AI must use this file

## Operating mode
The AI helping with implementation must follow these rules:

1. Work on **one phase at a time**.
2. Inside each phase, work on **one step at a time**.
3. Do **not skip ahead** unless the current step is complete.
4. Do **not implement advanced AI or automation before the base product works**.
5. Prefer **clean architecture, readable code, and small working increments**.
6. Every step must end with:
   - what was implemented
   - which files were created or changed
   - what still remains
   - how to test it manually
7. If a step needs clarification, the AI must propose the safest implementation that matches the software documentation.
8. The AI must keep the implementation aligned with:
   - Flutter mobile app
   - FastAPI backend
   - PostgreSQL database
   - AI-assisted but deterministic scheduling architecture

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

# 2) Product implementation strategy

## Main rule
Build **core product foundations first**, then build **core daily workflows**, then add **AI**, then add **advanced scheduling/automation**, then finish with **hardening and deployment**.

## Implementation order philosophy
The product should be built in this order:

1. development foundation
2. backend foundation
3. mobile foundation
4. authentication and onboarding
5. tasks and projects
6. dashboard and quick capture
7. notes, habits, focus, prayer
8. notifications and basic scheduling
9. AI parsing and smart suggestions
10. voice commands
11. analytics
12. adaptive scheduling and automation engine
13. production hardening and deployment

---

# 3) Final target architecture

## Mobile
- Flutter
- Riverpod
- Hive or SQLite for local caching
- local notifications

## Backend
- FastAPI
- modular service structure
- JWT authentication
- scheduling and automation services

## Database
- PostgreSQL
- user-owned relational schema
- audit timestamps
- support for task dependencies and schedule blocks

## AI
- LLM/NLP layer for parsing, interpretation, and suggestion
- deterministic scheduling layer for final placement and constraints
- later: human-aware adaptive scheduling and automation engine

---

# 4) Phase map

| Phase | Name | Main goal |
|---|---|---|
| 0 | Workspace & Repo Foundation | create clean project structure |
| 1 | Backend Core Foundation | get FastAPI + PostgreSQL + auth running |
| 2 | Flutter App Foundation | get app shell and navigation running |
| 3 | Authentication & Onboarding | complete first usable entry flow |
| 4 | Tasks & Projects Core | implement the most important productivity module |
| 5 | Dashboard & Quick Capture | create the daily command center |
| 6 | Notes, Habits, Focus, Prayer Core | complete major life modules |
| 7 | Notifications & Basic Scheduling | reminders + basic planning |
| 8 | AI MVP | text parsing, next action, simple daily plan |
| 9 | Voice MVP | Arabic/English command flow |
| 10 | Analytics MVP | useful personal insights |
| 11 | Adaptive Scheduling & Automation Engine | human-aware deeper intelligence |
| 12 | Hardening, QA, Release, Deployment | make it stable and publishable |

---

# 5) Phase 0 — Workspace & Repo Foundation

## Goal
Create a clean implementation base so all future work stays organized.

## Why first
Without a stable workspace, later AI-generated code becomes messy and inconsistent.

## Scope
- create root project folders
- create Flutter app
- create FastAPI backend
- create infrastructure folder
- create environment examples
- create README
- create coding conventions document

## Deliverables
- mono-repo or clean two-folder structure
- backend boots locally
- Flutter app boots locally
- Git initialized
- base `.env.example` files exist

## Suggested folder structure
```text
smart-life-planner/
├── mobile/
├── backend/
├── infrastructure/
├── docs/
├── scripts/
├── .gitignore
├── README.md
```

## Steps
### Step 0.1 Create repository structure
### Step 0.2 Initialize Flutter project
### Step 0.3 Initialize FastAPI project
### Step 0.4 Add Docker Compose for backend + db
### Step 0.5 Add README and environment examples
### Step 0.6 Define coding conventions and branch strategy

## Done when
- project runs locally
- backend and mobile folders exist
- Docker Compose starts PostgreSQL
- README explains how to run both sides

## AI instruction for this phase
Implement only project scaffolding and developer setup. Do not build features yet.

---

# 6) Phase 1 — Backend Core Foundation

## Goal
Build the backend base that everything depends on.

## Scope
- FastAPI app structure
- config management
- PostgreSQL connection
- Alembic migrations
- base models
- JWT auth
- users
- user settings
- health endpoint
- error handling
- OpenAPI docs working

## Deliverables
- backend starts successfully
- database migrations run
- user registration/login works
- protected route works
- settings table exists

## Steps
### Step 1.1 Create backend folder architecture
Use modules like:
- `core`
- `api`
- `models`
- `schemas`
- `services`
- `repositories`

### Step 1.2 Configure database
- SQLAlchemy / SQLModel / ORM choice
- Alembic
- PostgreSQL connection
- base migration

### Step 1.3 Implement users and user settings schema
Tables:
- users
- user_settings

### Step 1.4 Implement authentication
- register
- login
- get current user
- password hashing
- JWT

### Step 1.5 Implement base settings endpoints
- get settings
- update settings

### Step 1.6 Add backend quality basics
- env config
- exception handlers
- request validation
- logging
- `/health` endpoint

## Done when
- user can register
- user can log in
- JWT-secured endpoint works
- migrations are stable
- db schema is versioned

## Out of scope
- tasks
- AI
- voice
- notifications

## AI instruction for this phase
Focus only on clean backend foundation and authentication. Keep architecture modular.

---

# 7) Phase 2 — Flutter App Foundation

## Goal
Build the mobile app shell and architectural base.

## Scope
- Flutter app structure
- Riverpod setup
- theme
- localization shell
- app routing
- bottom navigation shell
- reusable UI foundation
- secure token storage placeholder
- API client foundation

## Deliverables
- app launches
- navigation shell exists
- placeholder screens exist
- Arabic/English localization structure exists
- API client layer exists

## Steps
### Step 2.1 Create app architecture
Suggested:
- `core`
- `features`
- `shared`
- `services`
- `routes`

### Step 2.2 Configure Riverpod
- auth provider
- app settings provider
- API service providers

### Step 2.3 Build app theme and base widgets
- dark/light support base
- typography
- buttons
- cards
- loading/error widgets

### Step 2.4 Build route system
Top-level routes:
- splash
- welcome
- sign in
- sign up
- onboarding
- home shell

### Step 2.5 Build main bottom navigation shell
Tabs:
- Home
- Tasks
- Focus
- Prayer
- Profile

### Step 2.6 Add localization framework
- English
- Arabic
- RTL support preparation

## Done when
- app opens into a working shell
- navigation is stable
- placeholder screens exist
- localization system works

## AI instruction for this phase
Build structure and navigation only. Use placeholders instead of real business logic where needed.

---

# 8) Phase 3 — Authentication & Onboarding

## Goal
Make the first complete user entry flow work end to end.

## Scope
- splash logic
- welcome screen
- sign up
- sign in
- logout
- forgot password placeholder
- onboarding flow
- first-time setup
- save preferences to backend

## Deliverables
- user can create account
- user can log in
- onboarding saves language, prayer settings, routine settings
- app enters authenticated shell after onboarding

## Steps
### Step 3.1 Splash and session check
### Step 3.2 Sign up screen + backend integration
### Step 3.3 Sign in screen + token storage
### Step 3.4 User profile/session state handling
### Step 3.5 Onboarding screens
Include:
- language
- location/city
- prayer settings
- goals
- routine
- permissions

### Step 3.6 Persist onboarding data
Save to:
- users
- user_settings

## Done when
- fresh user can install app, create account, finish onboarding, and enter app shell
- returning user skips onboarding

## AI instruction for this phase
Prioritize correctness and clean user state transitions.

---

# 9) Phase 4 — Tasks & Projects Core

## Goal
Implement the most important module in the app: tasks.

## Scope
- task_projects
- tasks
- subtasks
- task CRUD
- project CRUD
- task list filters
- task details
- create/edit task flow
- mark complete
- reopen
- delete / soft delete if chosen

## Deliverables
- end-to-end task system working from UI to database
- project grouping working
- task lists working
- task details working

## Steps
### Step 4.1 Backend task_projects + tasks + task_subtasks models
### Step 4.2 Task and project API endpoints
### Step 4.3 Flutter task list screens
- Inbox
- Today
- Upcoming
- Projects
- Completed

### Step 4.4 Create/edit task form
Fields:
- title
- description
- due date
- priority
- category
- recurrence
- project
- reminder

### Step 4.5 Task details screen
### Step 4.6 Project details screen
### Step 4.7 Subtasks
### Step 4.8 Mark complete / reopen / delete flows

## Done when
- user can fully manage tasks and projects
- task data persists correctly
- task flows are stable from UI to backend

## AI instruction for this phase
Do not add AI parsing yet. First make manual task management fully reliable.

---

# 10) Phase 5 — Dashboard & Quick Capture

## Goal
Build the daily command center of the app.

## Scope
- home dashboard
- daily overview
- top tasks
- quick capture input
- next prayer card placeholder/live if prayer already ready
- habit snapshot placeholder
- focus summary placeholder
- quick journal prompt placeholder
- productivity summary placeholder

## Deliverables
- Home becomes the default working screen
- quick capture flow exists
- dashboard loads aggregated data

## Steps
### Step 5.1 Create dashboard aggregation endpoint
### Step 5.2 Build Home screen sections
### Step 5.3 Build quick capture input
For now:
- allow manual classification or simple local classification
- save task or note

### Step 5.4 Connect top tasks and summary cards
### Step 5.5 Add loading, empty, and error states

## Done when
- Home feels like a usable daily command center
- dashboard loads quickly
- quick capture creates usable records

## AI instruction for this phase
Use simple logic first. This phase is about workflow, not advanced intelligence.

---

# 11) Phase 6 — Notes, Habits, Focus, Prayer Core

## Goal
Complete the major non-task life modules in their MVP form.

## Scope
- notes CRUD
- habits CRUD + logs + streaks
- focus sessions
- prayer times + prayer logs
- Quran goals + progress
- journal entries + mood + gratitude

## Deliverables
- all major product pillars exist in usable MVP form
- app now feels holistic, not just a task manager

## Steps
### Step 6.1 Notes module
Backend:
- notes table
- notes endpoints
Frontend:
- notes list
- note editor
- search

### Step 6.2 Habits module
Backend:
- habits
- habit_logs
Frontend:
- habits list
- mark complete
- streak display

### Step 6.3 Focus module
Backend:
- focus_sessions
Frontend:
- start session
- timer
- end session
- history

### Step 6.4 Prayer module
Backend:
- prayer logs
- prayer settings integration
- prayer time retrieval/calculation integration
Frontend:
- prayer screen
- mark prayer complete
- prayer history

### Step 6.5 Quran goal module
### Step 6.6 Journal module

## Done when
- notes, habits, focus, prayer, journal all work in MVP form
- data persists
- main screens feel connected

## AI instruction for this phase
Implement each module fully enough to be usable before moving to the next.

---

# 12) Phase 7 — Notifications & Basic Scheduling

## Goal
Make the app active and time-aware.

## Scope
- notification preferences
- task reminders
- habit reminders
- prayer notifications
- focus alerts
- Quran reminders
- basic daily plan generation
- timezone-aware handling

## Deliverables
- reminders are scheduled correctly
- notification settings control behavior
- a basic daily planning engine exists

## Steps
### Step 7.1 Notification data model and settings integration
### Step 7.2 Local notifications for focus and simple reminders
### Step 7.3 Backend-generated reminders for server-driven cases
### Step 7.4 Prayer notification rules
### Step 7.5 Basic scheduling engine
Input:
- tasks
- due dates
- priorities
- prayer times
- work hours

Output:
- suggested task order
- daily plan blocks

### Step 7.6 Home / task UI integration for daily plan

## Done when
- app can remind users reliably
- basic plan generation works
- timezones are handled correctly

## AI instruction for this phase
Keep scheduling deterministic and simple. No advanced automation yet.

---

# 13) Phase 8 — AI MVP

## Goal
Add the first real intelligence layer without overcomplicating the app.

## Scope
- natural language task parsing
- structured extraction
- smart clarification flow
- next action suggestion
- simple daily plan generation through AI-assisted interpretation + deterministic placement
- basic insights

## Deliverables
- user can type natural language and get structured tasks
- app can suggest what to do next
- basic AI support is visible and useful

## Steps
### Step 8.1 Backend AI service abstraction
### Step 8.2 `/ai/parse-task` endpoint
### Step 8.3 Quick capture → AI parse → confirmation flow
### Step 8.4 `/ai/next-action` endpoint
### Step 8.5 `/ai/daily-plan` endpoint
### Step 8.6 Basic insights endpoint
### Step 8.7 Save accepted AI outputs if needed (`ai_suggestions`)

## Done when
- quick capture can parse natural language tasks
- AI next action is usable
- AI suggestions remain safe and editable

## AI instruction for this phase
Keep AI assistive, transparent, and user-confirmed. Do not allow major silent writes.

---

# 14) Phase 9 — Voice MVP

## Goal
Add the highest-value voice features in Arabic and English.

## Scope
- microphone capture UI
- transcription pipeline
- voice command parsing
- voice-driven task creation
- start focus command
- next prayer query
- mark prayer complete
- daily plan / next action voice query

## Deliverables
- voice works for top-value commands
- transcript preview and confirmation flow exists
- Arabic and English both supported

## Steps
### Step 9.1 Voice UI states
- idle
- listening
- processing
- transcript preview
- success
- fail

### Step 9.2 Transcription integration
### Step 9.3 Intent classification for MVP intents
### Step 9.4 Parameter extraction
### Step 9.5 Validation + confirmation layer
### Step 9.6 Execute supported commands

## Done when
- user can create tasks and trigger core flows by voice
- low-confidence flows ask for confirmation
- failures fall back to manual input

## AI instruction for this phase
Keep voice narrow and reliable. Do not build full conversational assistant mode yet.

---

# 15) Phase 10 — Analytics MVP

## Goal
Turn product data into useful feedback.

## Scope
- productivity statistics
- habit stats
- focus stats
- prayer consistency
- dashboard summaries
- basic behavior insights

## Deliverables
- analytics dashboard works
- basic trends are visible
- insights feel meaningful

## Steps
### Step 10.1 analytics_snapshots or aggregation strategy
### Step 10.2 backend analytics endpoints
### Step 10.3 profile analytics screen
### Step 10.4 dashboard summary cards
### Step 10.5 basic behavioral insight generation

## Done when
- user can see progress and patterns
- data supports future personalization

## AI instruction for this phase
Prefer reliable computed metrics over fancy AI summaries.

---

# 16) Phase 11 — Adaptive Scheduling & Automation Engine (H-ASAE)

## Goal
Add the advanced intelligence layer after the base app is already stable.

## Scope
- task dependencies
- execution metadata
- human-aware task scoring
- dependency-aware eligibility
- overload detection
- next best action reasoning
- future-only replanning
- automation events
- automation actions
- schedule blocks
- schedule explanations

## Deliverables
- app evolves from a planner into an adaptive execution system
- advanced scheduling becomes explicit and explainable
- research-grade scheduling layer is now inside the product

## Steps
### Step 11.1 Extend task model
Add:
- difficulty_level
- energy_required
- is_splittable
- is_strict_time
- earliest_start_at
- latest_finish_at
- auto_schedule_enabled
- schedule_flexibility

### Step 11.2 Add task dependencies
Table:
- task_dependencies

UI:
- dependency selection
- blocked state

### Step 11.3 Add daily_schedules and schedule_blocks
### Step 11.4 Add automation_events and automation_actions
### Step 11.5 Implement dependency-aware eligibility
### Step 11.6 Implement weighted human-aware scoring
Factors:
- priority
- urgency
- dependency readiness
- duration fit
- energy-time match
- historical suitability
- placement friction

### Step 11.7 Implement overload detection
### Step 11.8 Implement future-only replanning
### Step 11.9 Add explanations for next best action and schedule decisions
### Step 11.10 Add UI surfaces
- Next Best Action card
- overload warning card
- schedule explanation
- schedule block lock state

## Done when
- advanced scheduling works without breaking user trust
- blocked tasks are handled correctly
- schedule decisions are explainable
- automation does not silently damage user plans

## AI instruction for this phase
This phase must remain deterministic, testable, and explainable. Avoid black-box autonomy.

---

# 17) Phase 12 — Hardening, QA, Release, Deployment

## Goal
Turn the working product into a stable, testable, deployable application.

## Scope
- bug fixing
- validation hardening
- error states
- performance improvements
- secure storage
- production config
- Dockerized backend deployment
- CI/CD basics
- backups
- release preparation

## Deliverables
- stable internal MVP
- beta-ready backend and mobile build
- deployment pipeline
- release checklist

## Steps
### Step 12.1 Full flow testing
Critical flows:
- auth
- onboarding
- tasks
- quick capture
- habits
- focus
- prayer
- notifications
- AI parse
- voice

### Step 12.2 Error and empty state pass
### Step 12.3 Security pass
- secure storage
- token handling
- auth checks
- ownership checks

### Step 12.4 Performance pass
### Step 12.5 Dockerized backend production setup
### Step 12.6 CI/CD basics
### Step 12.7 Backup process
### Step 12.8 Internal beta build
### Step 12.9 closed beta fixes
### Step 12.10 public beta / soft launch preparation

## Done when
- product is stable enough for real testers
- critical crashes are resolved
- deployment is repeatable
- data is protected

## AI instruction for this phase
Focus on reliability, polish, and release readiness rather than adding new features.

---

# 18) Cross-phase implementation rules

## Rule A — Backend before complex UI integration
If a feature depends on backend state, finish the backend contract first.

## Rule B — Manual workflow before AI workflow
Every important feature must work manually before AI assists it.

## Rule C — Core workflow before edge cases
Finish the happy path first, then add recovery/error states.

## Rule D — Stable data model before advanced automation
Do not build adaptive automation before the task/schedule data model is correct.

## Rule E — Explainability before autonomy
The system should be able to explain recommendations before it starts changing future plans automatically.

---

# 19) Definition of done per phase

A phase is complete only when all of the following are true:

- code compiles / runs
- migrations are stable
- major happy-path flow works
- loading and error states exist
- manual testing instructions exist
- no major blocker remains for the next phase

---

# 20) The exact way to use this with an AI assistant

Paste this roadmap to the AI and say:

```text
You are helping me implement Smart Life Planner.
Follow this roadmap strictly.
We will work one phase at a time and one step at a time.
Do not skip ahead.
At each step:
1) implement only that step
2) show the files you created/changed
3) show commands to run
4) explain how I test it
5) stop and wait for my confirmation before moving to the next step
If a step depends on a decision, choose the simplest clean implementation that matches the roadmap.
```

Then start with:

```text
Start with Phase 0, Step 0.1 only.
```

---

# 21) Recommended first execution order

Use this exact order:

1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 4
6. Phase 5
7. Phase 6
8. Phase 7
9. Phase 8
10. Phase 9
11. Phase 10
12. Phase 11
13. Phase 12

---

# 22) Final note

This roadmap is intentionally designed to:
- start with the main things
- build working foundations first
- reduce project risk
- avoid AI overengineering too early
- keep the product aligned with the main software documentation
- make AI-assisted implementation much more reliable and controlled
