import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/main_shell.dart';
import '../features/home/screens/tasks_screen.dart';
import '../features/home/screens/focus_screen.dart';
import '../features/home/screens/prayer_screen.dart';
import '../features/home/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: [
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
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
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
      ],
    ),
  ],
);