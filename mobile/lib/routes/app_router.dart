import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../features/habits/screens/habits_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/ai/screens/daily_plan_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/hasae/screens/ranked_tasks_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
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
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/daily-plan',
            builder: (context, state) => const DailyPlanScreen(),
          ),
          GoRoute(
            path: '/home/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/home/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/home/prayer',
            builder: (context, state) => const PrayerScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/home/change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/home/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/home/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/home/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/home/ranked-tasks',
            builder: (context, state) => const RankedTasksScreen(),
          ),
        ],
      ),
    ],
  );
});
