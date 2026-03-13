```smart-life-planner/
├── README.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── .env.example
├── .github/
│   ├── CODEOWNERS
│   ├── pull_request_template.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── task.md
│   └── workflows/
│       ├── mobile_ci.yml
│       ├── backend_ci.yml
│       ├── infra_ci.yml
│       ├── deploy_staging.yml
│       └── deploy_production.yml
│
├── docs/
│   ├── software-documentation.md
│   ├── architecture/
│   │   ├── system-overview.md
│   │   ├── database-design.md
│   │   ├── api-design.md
│   │   ├── ai-design.md
│   │   └── deployment-design.md
│   ├── product/
│   │   ├── roadmap.md
│   │   ├── backlog.md
│   │   ├── monetization.md
│   │   └── release-plan.md
│   └── qa/
│       ├── test-plan.md
│       ├── acceptance-criteria.md
│       └── test-cases.md
│
├── apps/
│   └── mobile/
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── android/
│       ├── ios/
│       ├── web/
│       ├── assets/
│       │   ├── images/
│       │   ├── icons/
│       │   ├── animations/
│       │   ├── audio/
│       │   └── fonts/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   ├── router/
│       │   │   │   ├── app_router.dart
│       │   │   │   └── route_names.dart
│       │   │   ├── theme/
│       │   │   │   ├── app_theme.dart
│       │   │   │   ├── colors.dart
│       │   │   │   └── typography.dart
│       │   │   ├── localization/
│       │   │   │   ├── app_localizations.dart
│       │   │   │   ├── en.arb
│       │   │   │   └── ar.arb
│       │   │   └── constants/
│       │   │       ├── app_constants.dart
│       │   │       └── storage_keys.dart
│       │   │
│       │   ├── core/
│       │   │   ├── config/
│       │   │   │   ├── env.dart
│       │   │   │   └── flavor_config.dart
│       │   │   ├── network/
│       │   │   │   ├── api_client.dart
│       │   │   │   ├── api_endpoints.dart
│       │   │   │   ├── auth_interceptor.dart
│       │   │   │   └── network_exceptions.dart
│       │   │   ├── storage/
│       │   │   │   ├── secure_storage_service.dart
│       │   │   │   ├── local_db_service.dart
│       │   │   │   └── cache_service.dart
│       │   │   ├── utils/
│       │   │   │   ├── date_utils.dart
│       │   │   │   ├── validators.dart
│       │   │   │   └── result.dart
│       │   │   ├── widgets/
│       │   │   │   ├── app_button.dart
│       │   │   │   ├── app_text_field.dart
│       │   │   │   ├── loading_view.dart
│       │   │   │   └── empty_state.dart
│       │   │   └── services/
│       │   │       ├── notification_service.dart
│       │   │       ├── permission_service.dart
│       │   │       ├── speech_service.dart
│       │   │       └── analytics_service.dart
│       │   │
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   │   ├── data/
│       │   │   │   │   ├── datasources/
│       │   │   │   │   ├── models/
│       │   │   │   │   └── repositories/
│       │   │   │   ├── domain/
│       │   │   │   │   ├── entities/
│       │   │   │   │   ├── repositories/
│       │   │   │   │   └── usecases/
│       │   │   │   └── presentation/
│       │   │   │       ├── providers/
│       │   │   │       ├── screens/
│       │   │   │       └── widgets/
│       │   │   │
│       │   │   ├── onboarding/
│       │   │   ├── dashboard/
│       │   │   ├── tasks/
│       │   │   ├── projects/
│       │   │   ├── notes/
│       │   │   ├── habits/
│       │   │   ├── journal/
│       │   │   ├── focus/
│       │   │   ├── prayer/
│       │   │   ├── quran/
│       │   │   ├── analytics/
│       │   │   ├── voice/
│       │   │   ├── ai_assistant/
│       │   │   ├── notifications/
│       │   │   └── settings/
│       │   │
│       │   └── shared/
│       │       ├── models/
│       │       ├── enums/
│       │       └── extensions/
│       │
│       └── test/
│           ├── unit/
│           ├── widget/
│           └── integration/
│
├── services/
│   └── backend/
│       ├── Dockerfile
│       ├── requirements.txt
│       ├── requirements-dev.txt
│       ├── pyproject.toml
│       ├── alembic.ini
│       ├── app/
│       │   ├── main.py
│       │   ├── core/
│       │   │   ├── config.py
│       │   │   ├── security.py
│       │   │   ├── database.py
│       │   │   ├── logging.py
│       │   │   └── constants.py
│       │   ├── api/
│       │   │   ├── deps.py
│       │   │   └── v1/
│       │   │       ├── api.py
│       │   │       ├── auth.py
│       │   │       ├── users.py
│       │   │       ├── settings.py
│       │   │       ├── dashboard.py
│       │   │       ├── tasks.py
│       │   │       ├── projects.py
│       │   │       ├── notes.py
│       │   │       ├── habits.py
│       │   │       ├── journal.py
│       │   │       ├── prayers.py
│       │   │       ├── quran.py
│       │   │       ├── focus.py
│       │   │       ├── analytics.py
│       │   │       ├── ai.py
│       │   │       ├── voice.py
│       │   │       └── notifications.py
│       │   ├── models/
│       │   │   ├── user.py
│       │   │   ├── user_settings.py
│       │   │   ├── task.py
│       │   │   ├── task_subtask.py
│       │   │   ├── task_project.py
│       │   │   ├── note.py
│       │   │   ├── habit.py
│       │   │   ├── habit_log.py
│       │   │   ├── journal_entry.py
│       │   │   ├── prayer_log.py
│       │   │   ├── quran_goal.py
│       │   │   ├── quran_progress_log.py
│       │   │   ├── focus_session.py
│       │   │   ├── notification.py
│       │   │   ├── ai_suggestion.py
│       │   │   └── analytics_snapshot.py
│       │   ├── schemas/
│       │   │   ├── auth.py
│       │   │   ├── user.py
│       │   │   ├── settings.py
│       │   │   ├── task.py
│       │   │   ├── project.py
│       │   │   ├── note.py
│       │   │   ├── habit.py
│       │   │   ├── journal.py
│       │   │   ├── prayer.py
│       │   │   ├── quran.py
│       │   │   ├── focus.py
│       │   │   ├── analytics.py
│       │   │   ├── ai.py
│       │   │   ├── voice.py
│       │   │   └── notification.py
│       │   ├── repositories/
│       │   │   ├── user_repository.py
│       │   │   ├── task_repository.py
│       │   │   ├── note_repository.py
│       │   │   ├── habit_repository.py
│       │   │   ├── prayer_repository.py
│       │   │   └── focus_repository.py
│       │   ├── services/
│       │   │   ├── auth_service.py
│       │   │   ├── task_service.py
│       │   │   ├── dashboard_service.py
│       │   │   ├── prayer_service.py
│       │   │   ├── quran_service.py
│       │   │   ├── habit_service.py
│       │   │   ├── journal_service.py
│       │   │   ├── focus_service.py
│       │   │   ├── analytics_service.py
│       │   │   ├── notification_service.py
│       │   │   ├── scheduling_service.py
│       │   │   ├── voice_service.py
│       │   │   └── ai_service.py
│       │   ├── ai/
│       │   │   ├── prompts/
│       │   │   ├── parsers/
│       │   │   ├── classifiers/
│       │   │   ├── planners/
│       │   │   └── insights/
│       │   ├── workers/
│       │   │   ├── reminder_worker.py
│       │   │   ├── prayer_schedule_worker.py
│       │   │   └── analytics_worker.py
│       │   └── utils/
│       │       ├── datetime_helpers.py
│       │       ├── enums.py
│       │       └── exceptions.py
│       ├── alembic/
│       │   ├── env.py
│       │   ├── script.py.mako
│       │   └── versions/
│       └── tests/
│           ├── unit/
│           ├── integration/
│           └── api/
│
├── infrastructure/
│   ├── compose/
│   │   ├── compose.dev.yaml
│   │   ├── compose.staging.yaml
│   │   └── compose.prod.yaml
│   ├── nginx/
│   │   └── nginx.conf
│   ├── scripts/
│   │   ├── dev-up.sh
│   │   ├── dev-down.sh
│   │   ├── migrate.sh
│   │   ├── backup-db.sh
│   │   └── restore-db.sh
│   ├── env/
│   │   ├── backend.env.example
│   │   ├── db.env.example
│   │   └── mobile.env.example
│   └── monitoring/
│       └── README.md
│
├── tools/
│   ├── seed/
│   │   ├── seed_dev_data.py
│   │   └── seed_demo_user.py
│   └── helpers/
│       └── generate_icons.sh
│
└── .vscode/
    ├── settings.json
    ├── launch.json
    └── extensions.json
```
