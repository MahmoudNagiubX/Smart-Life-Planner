import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const ProviderScope(child: SmartLifePlannerApp()));
}

class SmartLifePlannerApp extends StatelessWidget {
  const SmartLifePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Life Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}                  