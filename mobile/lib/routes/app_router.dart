import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/change_password_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
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
import '../features/home/screens/feature_placeholder_screen.dart';
import '../features/habits/screens/habits_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/tasks/screens/task_details_screen.dart';
import '../features/tasks/screens/project_timeline_screen.dart';
import '../features/ai/screens/daily_plan_screen.dart';
import '../features/ai/screens/ai_life_coach_placeholder_screen.dart';
import '../features/ai/screens/ai_life_coach_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/context/screens/context_intelligence_screen.dart';
import '../features/hasae/screens/ranked_tasks_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/prayer/screens/prayer_settings_screen.dart';
import '../features/prayer/screens/quran_goal_screen.dart';
import '../features/prayer/screens/qibla_screen.dart';
import '../features/prayer/screens/ramadan_mode_screen.dart';
import '../features/prayer/screens/spiritual_upgrades_screen.dart';
import '../features/voice/screens/voice_capture_screen.dart';
import '../features/voice/screens/voice_future_capabilities_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.signUp ||
          state.matchedLocation == AppRoutes.verifyEmail ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (isUnknown) return null;
      if (!isAuthenticated && !isAuthRoute) return AppRoutes.welcome;

      if (isAuthenticated) {
        final isOnboardingCompleted =
            authState.user?['onboarding_completed'] == true;
        if (!isOnboardingCompleted &&
            state.matchedLocation != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        } else if (isOnboardingCompleted &&
            (isAuthRoute || state.matchedLocation == AppRoutes.onboarding)) {
          return AppRoutes.home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const FeaturePlaceholderScreen(
          title: 'Splash',
          description: 'Startup status and session checks will appear here.',
          icon: Icons.bolt,
        ),
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
            builder: (context, state) => AiLifeCoachPlaceholderScreen(
              featureId: state.pathParameters['featureId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.taskCreate,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Create Task',
              description: 'Task creation is available from the task sheet.',
              icon: Icons.add_task,
            ),
          ),
          GoRoute(
            path: AppRoutes.taskEdit,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Edit Task',
              description:
                  'Task editing will open here once full details land.',
              icon: Icons.edit_note,
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
            path: AppRoutes.focusSession,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Active Focus Session',
              description: 'Live focus timer and session controls.',
              icon: Icons.timer_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.focusHistory,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Focus History',
              description: 'Past focus sessions and summaries.',
              icon: Icons.history,
            ),
          ),
          GoRoute(
            path: AppRoutes.prayer,
            builder: (context, state) => const PrayerScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayerHistory,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Prayer History',
              description: 'Prayer tracking history and consistency.',
              icon: Icons.calendar_month,
              accentColor: AppColors.prayerGold,
            ),
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
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Journal',
              description: 'Daily reflections and journal entries.',
              icon: Icons.auto_stories_outlined,
              destructiveActionLabel: 'Delete Journal Entry',
              destructiveActionTitle: 'Delete Journal Entry',
              destructiveActionMessage:
                  'Delete this journal entry? This action will require confirmation before anything is removed.',
              destructiveActionDoneMessage:
                  'Journal deletion is not active on this placeholder screen.',
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Settings',
              description: 'Account, app preferences, and privacy controls.',
              icon: Icons.settings_outlined,
              destructiveActionLabel: 'Clear Local Cache',
              destructiveActionTitle: 'Clear Local Cache',
              destructiveActionMessage:
                  'Clear local cache on this device? This may remove downloaded or temporary app data.',
              destructiveActionDoneMessage:
                  'Local cache clearing is not active on this placeholder screen.',
            ),
          ),
          GoRoute(
            path: AppRoutes.notificationSettings,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Notification Settings',
              description: 'Reminder channels, quiet hours, and permissions.',
              icon: Icons.notifications_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.languageSettings,
            builder: (context, state) => const FeaturePlaceholderScreen(
              title: 'Language And Localization',
              description: 'Arabic and English language preferences.',
              icon: Icons.language,
            ),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
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
