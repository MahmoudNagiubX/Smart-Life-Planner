# Flutter Screen Design Audit
_Last updated: 2026-05-02_

## Screen Audit Table

| Flutter screen / route | Current file | Screenshot reference | Status | Design action | Priority |
|---|---|---|---|---|---|
| Theme system | `core/theme/app_colors.dart` + `app_theme.dart` | tokens.css | needs redesign | restyle using design system | **P0** |
| Bottom nav shell | `home/screens/main_shell.dart` | (all screenshots) | needs redesign | restyle using design system | **P0** |
| `/` Splash | `auth/screens/splash_screen.dart` | `claude_design_splash.png` | has reference screenshot | clone from screenshot | P1 |
| `/welcome` | `auth/screens/welcome_screen.dart` | `claude_design_welcome.png` | has reference screenshot | clone from screenshot | P1 |
| `/sign-in` | `auth/screens/sign_in_screen.dart` | `claude_design_sign_in.png` | has reference screenshot | clone from screenshot | P1 |
| `/home` Home | `home/screens/home_screen.dart` | `claude_design_home.png` | has reference screenshot | clone from screenshot | P1 |
| `/home/tasks` Tasks | `home/screens/tasks_screen.dart` | `claude_design_tasks_today.png` | has reference screenshot | clone from screenshot | P1 |
| `/home/tasks` create sheet | `tasks/screens/create_task_sheet.dart` | `claude_design_create_task.png` | has reference screenshot | clone from screenshot | P1 |
| `/home/focus` Focus | `home/screens/focus_screen.dart` | `claude_design_focus_home.png` + `claude_design_focus_active.png` | has reference screenshot | clone from screenshot | P1 |
| `/home/prayer` Prayer | `home/screens/prayer_screen.dart` | `claude_design_prayer_home.png` | has reference screenshot | clone from screenshot | P1 |
| `/home/profile` Profile | `home/screens/profile_screen.dart` | `claude_design_profile_settings.png` | has reference screenshot | clone from screenshot | P1 |
| `/sign-up` | `auth/screens/sign_up_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P2 |
| `/onboarding` | `onboarding/screens/onboarding_screen.dart` | `claude_design_onboarding_goals.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/habits` | `habits/screens/habits_screen.dart` | `claude_design_habits_main.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/notes` | `notes/screens/notes_screen.dart` | `claude_design_notes_main.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/analytics` | `analytics/screens/analytics_screen.dart` | `claude_design_analytics.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/notifications` | `reminders/screens/notification_center_screen.dart` | `claude_design_notification_center.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/daily-plan` | `ai/screens/daily_plan_screen.dart` | `claude_design_schedule.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/ai-coach` | `ai/screens/ai_life_coach_screen.dart` | `claude_design_AI_assistant.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/voice-capture` | `voice/screens/voice_capture_screen.dart` | `claude_design_quick_capture.png` | has reference screenshot | clone from screenshot | P2 |
| `/home/tasks/:taskId` | `tasks/screens/task_details_screen.dart` | no screenshot | no screenshot but exists | keep logic and upgrade UI | P3 |
| `/home/projects/:projectId` | `tasks/screens/project_timeline_screen.dart` | no screenshot | no screenshot but exists | keep logic and upgrade UI | P3 |
| `/home/focus/settings` | `focus/screens/focus_settings_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/prayer/history` | `prayer/screens/prayer_history_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/prayer/quran-goal` | `prayer/screens/quran_goal_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/prayer/qibla` | `prayer/screens/qibla_screen.dart` | no screenshot | no screenshot but exists | keep logic and upgrade UI | P3 |
| `/home/prayer/spiritual-upgrades` | `prayer/screens/spiritual_upgrades_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/prayer/settings` | `prayer/screens/prayer_settings_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/settings` | `settings/screens/app_settings_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/settings/notifications` | `reminders/screens/notification_settings_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/settings/language` | `settings/screens/language_settings_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/ranked-tasks` | `hasae/screens/ranked_tasks_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/about` | `support/screens/about_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/support` | `support/screens/support_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/change-password` | `auth/screens/change_password_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/verify-email` | `auth/screens/verify_email_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/forgot-password` | `auth/screens/forgot_password_screen.dart` | no screenshot | no screenshot but exists | restyle using design system | P3 |
| `/home/journal` | `DeferredScopeScreen` | `claude_design_journal_entry.png` | deferred | show honest deferred state | deferred |
| `/home/prayer/ramadan` | `prayer/screens/ramadan_mode_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
| `/home/prayer/dhikr-reminders` | `prayer/screens/dhikr_reminders_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
| `/home/prayer/islamic-calendar` | `prayer/screens/islamic_calendar_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
| `/home/ai-coach/goal-roadmap` | `ai/screens/goal_roadmap_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
| `/home/ai-coach/study-planner` | `ai/screens/study_planner_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
| `/home/context-intelligence` | `context/screens/context_intelligence_screen.dart` | no screenshot | deferred | show honest deferred state | deferred |
