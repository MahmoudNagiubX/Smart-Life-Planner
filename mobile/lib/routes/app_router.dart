import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/home/screens/home_screen.dart';

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
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);