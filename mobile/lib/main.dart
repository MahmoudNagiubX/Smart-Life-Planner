import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_life_planner/core/l10n/app_localizations.dart';
import 'core/monitoring/crash_monitoring_service.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'routes/app_router.dart';

void main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await CrashMonitoringService.initialize();

      try {
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.requestPermissions();
      } catch (error, stackTrace) {
        CrashMonitoringService.recordError(
          error,
          stackTrace,
          reason: 'Notification startup',
        );
      }

      runApp(const ProviderScope(child: SmartLifePlannerApp()));
    },
    (error, stackTrace) {
      CrashMonitoringService.recordError(error, stackTrace, fatal: true);
    },
  );
}

class SmartLifePlannerApp extends ConsumerWidget {
  const SmartLifePlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Smart Life Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
