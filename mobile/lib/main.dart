import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_life_planner/core/l10n/app_localizations.dart';
import 'core/monitoring/crash_monitoring_service.dart';
import 'core/notifications/notification_action_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/settings/providers/app_settings_provider.dart';
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
    final authState = ref.watch(authProvider);
    final settingsState = ref.watch(appSettingsProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        unawaited(ref.read(appSettingsProvider.notifier).loadSettings());
      } else if (next.status == AuthStatus.unauthenticated) {
        ref.read(appSettingsProvider.notifier).reset();
      }
    });

    if (authState.status == AuthStatus.authenticated &&
        !settingsState.hasLoaded &&
        !settingsState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appSettingsProvider.notifier).loadSettings();
      });
    }

    final appSettings = settingsState.settings;
    final locale = switch (appSettings?.language) {
      'ar' => const Locale('ar'),
      'en' => const Locale('en'),
      _ => null,
    };

    NotificationService().setResponseHandler((response) {
      unawaited(
        NotificationActionHandler(ref: ref, router: router).handle(response),
      );
    });

    return MaterialApp.router(
      title: 'Smart Life Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appSettings?.themeMode ?? ThemeMode.dark,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
