import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/change_password_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/home/screens/tasks_screen.dart';
import '../features/home/screens/focus_screen.dart';
import '../features/home/screens/prayer_screen.dart';
import '../features/home/screens/profile_screen.dart';
import '../features/home/screens/deferred_scope_screen.dart';
import '../features/focus/screens/focus_settings_screen.dart';
import '../features/habits/screens/habits_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/tasks/screens/task_details_screen.dart';
import '../features/tasks/screens/project_timeline_screen.dart';
import '../features/ai/screens/daily_plan_screen.dart';
import '../features/ai/screens/ai_life_coach_placeholder_screen.dart';
import '../features/ai/screens/ai_life_coach_screen.dart';
import '../features/ai/screens/goal_roadmap_screen.dart';
import '../features/ai/screens/study_planner_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/context/screens/context_intelligence_screen.dart';
import '../features/hasae/screens/ranked_tasks_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/prayer/screens/prayer_settings_screen.dart';
import '../features/prayer/screens/prayer_history_screen.dart';
import '../features/prayer/screens/quran_goal_screen.dart';
import '../features/prayer/screens/qibla_screen.dart';
import '../features/prayer/screens/ramadan_mode_screen.dart';
import '../features/prayer/screens/spiritual_upgrades_screen.dart';
import '../features/prayer/screens/dhikr_reminders_screen.dart';
import '../features/prayer/screens/islamic_calendar_screen.dart';
import '../features/reminders/screens/notification_center_screen.dart';
import '../features/reminders/screens/notification_settings_screen.dart';
import '../features/settings/screens/app_settings_screen.dart';
import '../features/settings/screens/language_settings_screen.dart';
import '../features/support/screens/about_screen.dart';
import '../features/support/screens/support_screen.dart';
import '../features/voice/screens/voice_capture_screen.dart';
import '../features/voice/screens/voice_future_capabilities_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRouteRefresh(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.signUp ||
          state.matchedLocation == AppRoutes.verifyEmail ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (isUnknown) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }
      if (!isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.welcome;
      }
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.welcome;

      if (isAuthenticated) {
        final isOnboardingCompleted =
            authState.user?['onboarding_completed'] == true;
        if (!isOnboardingCompleted &&
            state.matchedLocation != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        } else if (isOnboardingCompleted &&
            (isAuthRoute ||
                state.matchedLocation == AppRoutes.splash ||
                state.matchedLocation == AppRoutes.onboarding)) {
          return AppRoutes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => VerifyEmailScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
          initialDevelopmentCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.dailyPlan,
            builder: (context, state) => const DailyPlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiCoach,
            builder: (context, state) => const AiLifeCoachScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiCoachFeature,
            builder: (context, state) {
              final featureId = state.pathParameters['featureId'] ?? '';
              if (featureId == 'goal-roadmap') {
                return const GoalRoadmapScreen();
              }
              if (featureId == 'study-planner') {
                return const StudyPlannerScreen();
              }
              return AiLifeCoachPlaceholderScreen(featureId: featureId);
            },
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.taskCreate,
            builder: (context, state) => const DeferredScopeScreen(
              title: 'Create Task',
              icon: Icons.add_task,
              description:
                  'The standalone create-task route is deferred for now.',
              availableNow:
                  'Create tasks from the Tasks screen using the real task sheet.',
            ),
          ),
          GoRoute(
            path: AppRoutes.taskEdit,
            builder: (context, state) => const DeferredScopeScreen(
              title: 'Edit Task',
              icon: Icons.edit_note,
              description: 'The standalone task edit route is deferred.',
              availableNow:
                  'Open Task Details for real task data and completion history.',
            ),
          ),
          GoRoute(
            path: AppRoutes.taskDetails,
            builder: (context, state) =>
                TaskDetailsScreen(taskId: state.pathParameters['taskId'] ?? ''),
          ),
          GoRoute(
            path: AppRoutes.projectDetails,
            builder: (context, state) => ProjectTimelineScreen(
              projectId: state.pathParameters['projectId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.focus,
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: AppRoutes.focusSettings,
            builder: (context, state) => const FocusSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.focusSession,
            builder: (context, state) => const DeferredScopeScreen(
              title: 'Active Focus Session',
              icon: Icons.timer_outlined,
              description:
                  'A separate active-session route is deferred from the MVP.',
              availableNow:
                  'Use the Focus tab for the real timer, breaks, settings, and reports.',
            ),
          ),
          GoRoute(
            path: AppRoutes.focusHistory,
            builder: (context, state) => const DeferredScopeScreen(
              title: 'Focus History',
              icon: Icons.history,
              description: 'The full focus history route is deferred.',
              availableNow:
                  'Recent sessions and report summary are available in the Focus tab.',
            ),
          ),
          GoRoute(
            path: AppRoutes.prayer,
            builder: (context, state) => const PrayerScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayerHistory,
            builder: (context, state) => const PrayerHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.quranGoal,
            builder: (context, state) => const QuranGoalScreen(),
          ),
          GoRoute(
            path: AppRoutes.qibla,
            builder: (context, state) => const QiblaScreen(),
          ),
          GoRoute(
            path: AppRoutes.ramadan,
            builder: (context, state) => const RamadanModeScreen(),
          ),
          GoRoute(
            path: AppRoutes.dhikrReminders,
            builder: (context, state) => const DhikrRemindersScreen(),
          ),
          GoRoute(
            path: AppRoutes.islamicCalendar,
            builder: (context, state) => const IslamicCalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.spiritualUpgrades,
            builder: (context, state) => const SpiritualUpgradesScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayerSettings,
            builder: (context, state) => const PrayerSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.support,
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: AppRoutes.changePassword,
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: AppRoutes.habits,
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: AppRoutes.notes,
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: AppRoutes.journal,
            builder: (context, state) => const DeferredScopeScreen(
              title: 'Journal',
              icon: Icons.auto_stories_outlined,
              description:
                  'The standalone journal module is deferred from this MVP pass.',
              availableNow:
                  'Use Notes for real persisted reflections, voice notes, checklists, tags, and reminders.',
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const AppSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.notificationCenter,
            builder: (context, state) => const NotificationCenterScreen(),
          ),
          GoRoute(
            path: AppRoutes.notificationSettings,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.languageSettings,
            builder: (context, state) => const LanguageSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: AppRoutes.rankedTasks,
            builder: (context, state) => const RankedTasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.voiceCapture,
            builder: (context, state) => const VoiceCaptureScreen(),
          ),
          GoRoute(
            path: AppRoutes.voiceFutureCapability,
            builder: (context, state) => VoiceFutureCapabilitiesScreen(
              capabilityId: state.pathParameters['capabilityId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.contextIntelligence,
            builder: (context, state) => const ContextIntelligenceScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthRouteRefresh extends ChangeNotifier {
  _AuthRouteRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) => notifyListeners());
  }
}
