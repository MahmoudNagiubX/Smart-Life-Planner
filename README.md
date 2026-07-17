<div align="center">

# 🌌 Smart Life Planner

### AI-Powered Productivity, Lifestyle & Spiritual Planning App

**A modern personal life operating system that combines tasks, notes, habits, focus, voice capture, reminders, spiritual planning, and intelligent suggestions in one organized mobile experience.**

<br />

![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-6C5CE7?style=for-the-badge)
![AI](https://img.shields.io/badge/AI-Assisted%20Planning-FF4FD8?style=for-the-badge)

<br />

<img src="docs/Cover.png" alt="Smart Life Planner Cover" width="780" />

<br />

**Built by [Mahmoud Nagiub](https://github.com/MahmoudNagiubX)**  
Software Engineering Student · AI & Software Engineering

</div>

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Why Smart Life Planner?](#-why-smart-life-planner)
- [Key Features](#-key-features)
- [H-ASAE Scheduling Engine](#-h-asae-scheduling-engine)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [How to Run](#-how-to-run)
- [Testing](#-testing)
- [Current Status](#-current-status)
- [Author](#-author)

---

## 🌍 Overview

**Smart Life Planner** is a full-stack Flutter + FastAPI application designed to help users manage their day from one place.

Instead of switching between separate apps for tasks, notes, focus, habits, reminders, and prayer tools, Smart Life Planner unifies them into a single intelligent workflow.

> **Smart Life Planner is more than a task manager — it is a personal life operating system.**

It helps users:

- plan their day clearly
- capture ideas instantly
- organize tasks with multiple productivity views
- stay focused with structured focus sessions
- build consistent habits
- track prayer, Quran, Ramadan, and spiritual goals
- receive smart suggestions based on real daily context

---

## 🎯 Why Smart Life Planner?

Most productivity tools solve only one part of life:

| Need | Typical App Type | Limitation |
|---|---|---|
| Tasks | Todoist / TickTick style tools | Task-focused only |
| Notes | Google Keep style tools | Notes are disconnected from planning |
| Focus | Pomodoro apps | Timer without full daily context |
| Habits | Habit trackers | Separate from tasks and goals |
| Prayer | Prayer apps | Spiritual routine isolated from productivity |

**Smart Life Planner combines productivity, self-improvement, and spiritual balance in one connected system.**

---

## ✨ Key Features

### 🔐 Authentication & Account

- Email/password registration and login
- Email verification and password reset codes
- Google and Apple Sign-In support with setup-aware configuration checks
- Profile, settings, support, and delete-account flow

### 🧭 Personalized Onboarding

The onboarding flow asks for language, country/city, goals, wake/sleep time, daily rhythm, prayer preferences, and permissions.

This allows the app to personalize the dashboard, habits, prayer setup, and suggestions from the first launch.

### 🏠 Smart Dashboard

The Home dashboard gives a clear daily overview:

- daily progress
- today’s tasks
- next prayer
- focus shortcut
- habits overview
- AI suggestion card
- quick access through the center action button

### ⚡ Quick Capture + Voice

Users can quickly create:

- tasks
- notes
- checklists
- voice tasks
- voice notes

Voice capture can analyze a transcript, extract tasks, detect dates or deadlines, assign priority, and prepare the result before adding it to the task system.

### 📋 Task Management

Task management supports several productivity styles:

- task list
- pending / completed tasks
- GTD workflow
- Kanban board
- Eisenhower Matrix
- Calendar view
- project and timeline views

### 🎯 Focus System

The Focus module helps users turn plans into action with focus sessions, timer-based work, focus tracking, and visual progress.

### 🔁 Habit Tracking

The habit system supports habit creation, completion, streaks, reminders, progress summaries, and categories for personal growth.

### 📝 Notes System

The notes module supports text notes, structured blocks, checklists, tags, pinned notes, archive state, reminders, voice-note flows, and task-linked notes.

### 🕌 Spiritual Planning

Smart Life Planner includes a dedicated spiritual module:

- prayer tracking
- missed prayer tracking
- prayer history
- Qibla direction
- Quran goal tracking
- Ramadan mode
- Islamic calendar
- Dhikr reminders
- prayer settings

This is one of the main areas that makes the app different from normal productivity apps.

### 🔔 Reminders & Notifications

The reminder system supports task, note, habit, prayer, and Ramadan reminders with snooze/reschedule logic, notification center support, and stale reminder invalidation.

---

## 🧠 H-ASAE Scheduling Engine

The **Human-Aware Adaptive Scheduling & Automation Engine (H-ASAE)** is the deterministic, explainable planning layer behind Smart Life Planner. Rather than relying on an opaque model, it combines rule-based eligibility, weighted task scoring, overload detection, prayer-aware time constraints, and user-confirmed schedule generation.

Traditional task apps usually ask:

> “What tasks are due?”

Smart Life Planner asks:

> “What makes sense for this user right now?”

The engine considers:

- priorities
- deadlines
- available time
- habits
- focus sessions
- energy level
- prayer times
- daily rhythm
- personal routine

Then it helps users decide what to focus on next, what can be delayed, and how to balance work, self-improvement, and spiritual commitments.

---

## 🏗️ Architecture

```text
┌────────────────────────────────────────────┐
│              Flutter Mobile App            │
│       UI · Riverpod · Local Features        │
└──────────────────────┬─────────────────────┘
                       │ REST API
┌──────────────────────▼─────────────────────┐
│                FastAPI Backend              │
│ Auth · Tasks · Notes · Habits · Prayer · AI │
└──────────────────────┬─────────────────────┘
                       │ SQLAlchemy / Alembic
┌──────────────────────▼─────────────────────┐
│                 PostgreSQL DB               │
│ Users · Tasks · Notes · Habits · Reminders  │
└────────────────────────────────────────────┘
```

### Main Mobile Modules

- Auth and onboarding
- Home dashboard
- Quick Capture
- Tasks
- Notes
- Habits
- Focus
- Prayer / Qibla / Ramadan / Quran
- Profile / Settings / Support

### Main Backend Modules

- Authentication
- User settings
- Tasks and projects
- Notes
- Habits
- Focus sessions
- Prayer and spiritual tools
- Reminders
- AI/voice contracts
- Analytics

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter / Dart |
| State Management | Riverpod |
| Backend | FastAPI / Python |
| Database | PostgreSQL |
| ORM / Migrations | SQLAlchemy + Alembic |
| Auth | JWT |
| Notifications | Local notifications + backend reminder model |
| AI / Voice | Groq API, Whisper Large v3 Turbo, Llama task parsing, and deterministic H-ASAE scheduling |

---

## 📁 Project Structure

```text
Smart-Life-Planner/
├── backend/
│   ├── app/
│   │   ├── api/              # FastAPI routes
│   │   ├── core/             # config, security, shared setup
│   │   ├── models/           # SQLAlchemy models
│   │   ├── repositories/     # database access layer
│   │   ├── schemas/          # Pydantic DTOs
│   │   └── services/         # business logic and integrations
│   ├── alembic/              # database migrations
│   ├── tests/                # backend tests
│   └── requirements.txt
│
├── mobile/
│   ├── lib/
│   │   ├── core/             # networking, theme, notifications, shared utilities
│   │   ├── features/         # auth, home, tasks, notes, habits, prayer, etc.
│   │   └── routes/           # app routing
│   ├── assets/               # images, icons, fonts, app assets
│   ├── test/                 # Flutter tests
│   └── pubspec.yaml
│
├── docs/                     # audits, reliability gates, planning docs
├── README.md
└── .gitignore
```

---

## 🚀 How to Run

### 1. Clone the Repository

```bash
git clone https://github.com/MahmoudNagiubX/Smart-Life-Planner.git
cd Smart-Life-Planner
```

---

## ⚙️ Backend Setup

```bash
cd backend
python -m venv .venv
```

Activate the environment:

```bash
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

```bash
# macOS / Linux
source .venv/bin/activate
```

Install dependencies:

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Create `backend/.env`:

```env
ENVIRONMENT=development
DATABASE_URL=postgresql+psycopg2://postgres:YOUR_PASSWORD@localhost:5432/smart_life_planner
SECRET_KEY=change_me_to_a_secure_secret
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
GROQ_API_KEY=your_groq_api_key

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_gmail_app_password
SMTP_FROM_EMAIL=your_email@gmail.com
SMTP_FROM_NAME=Smart Life Planner
SMTP_USE_TLS=true

GOOGLE_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
APPLE_APP_BUNDLE_ID=com.yourcompany.smartlifeplanner
```

Run migrations:

```bash
python -m alembic upgrade head
```

Start the backend:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Check health:

```text
http://localhost:8000/health
```

Expected:

```json
{"status": "ok", "service": "smart-life-planner-api"}
```

---

## 📱 Mobile App Setup

```bash
cd mobile
flutter pub get
```

Run on Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Run on a real Android phone:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:8000/api/v1
```

Example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.8:8000/api/v1
```

> A real phone cannot use `127.0.0.1` for the backend. Use your computer LAN IP and keep both devices on the same Wi-Fi.

---

## 🔑 Social Sign-In Notes

Google and Apple sign-in require external provider configuration.

For Google:

- Android package name must match the registered app
- SHA-1 / SHA-256 fingerprints must be added
- Flutter `default_web_client_id` must match backend `GOOGLE_CLIENT_ID`
- the backend must use the Web OAuth Client ID

For Apple:

- set `APPLE_APP_BUNDLE_ID` to the iOS bundle ID
- enable the Sign in with Apple capability for the iOS app
- display the Apple button only on supported platforms

When provider settings are missing or invalid, the backend returns setup-aware errors instead of silently accepting unverified tokens.

---

## 📧 Email Verification Notes

For Gmail SMTP, use a Google App Password, not your normal Gmail password.

For local/college demos, keep:

```env
ENVIRONMENT=development
```

Development mode allows safe verification/reset codes for testing.

---

## 🧪 Testing

Backend tests:

```bash
cd backend
python -m pytest
```

Migration checks:

```bash
python -m alembic heads
python -m alembic current
```

Flutter analysis and tests:

```bash
cd mobile
flutter analyze
flutter test
```

---

## ✅ Current Status

Smart Life Planner is prepared as a **college submission / demo-ready MVP**.

Stable demo flows include:

- register / login / email verification
- onboarding
- dashboard
- quick capture and voice actions
- tasks and calendar
- notes
- habits
- focus
- prayer, Qibla, Quran Goal, Ramadan Mode
- profile, settings, support, and logout

Known caveats:

- Google Sign-In requires correct external OAuth setup
- Apple Sign-In requires the correct bundle ID and Apple capability configuration
- real SMTP requires a Gmail App Password or another mail provider
- advanced AI Life Coach detail pages are deferred
- standalone journal route is deferred
- some advanced smart-note AI/OCR actions are future work depending on the active build

---

## 🧠 Algorithms Used

| Algorithm / Technique | Used For |
|---|---|
| Rule-based classification | GTD buckets, Eisenhower Matrix, prayer states |
| Weighted scoring | priorities and smart suggestions |
| Time-window checks | reminders, prayer-aware planning, focus blocks |
| Sequential counting | habit streaks and focus streaks |
| Aggregation | dashboard, analytics, weekly summaries |
| Great-circle bearing formula | Qibla direction |
| NLP / information extraction | voice capture and quick task parsing |
| State-machine logic | auth flow, focus sessions, reminder lifecycle |
| Defensive parsing | stable mobile handling for old/null data |

---

## 👨‍💻 Author

<div align="center">

### Mahmoud Nagiub

**Software Engineering Student · AI & Software Engineering**

[![GitHub](https://img.shields.io/badge/GitHub-MahmoudNagiubX-181717?style=for-the-badge&logo=github)](https://github.com/MahmoudNagiubX)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mahmoudnagiubb/)

</div>

---

<div align="center">

## ⭐ Smart Life Planner

**Plan better. Focus deeper. Grow consistently. Live a balanced life.**

</div>
