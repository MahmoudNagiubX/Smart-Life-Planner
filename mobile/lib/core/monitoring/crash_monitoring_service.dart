import 'package:flutter/foundation.dart';

class CrashMonitoringService {
  static bool _initialized = false;

  @visibleForTesting
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordFlutterError(details, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      recordError(error, stackTrace, fatal: true);
      return true;
    };

    if (kDebugMode) {
      debugPrint('[CrashMonitoring] initialized in debug console mode');
    }
  }

  static void recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) {
    recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: fatal,
      reason: details.context?.toDescription(),
    );
  }

  static void recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) {
    if (kDebugMode) {
      final severity = fatal ? 'fatal' : 'nonfatal';
      final reasonText = reason == null ? '' : ' reason=$reason';
      debugPrint(
        '[CrashMonitoring] $severity error_type=${error.runtimeType}$reasonText',
      );
      if (stackTrace != null) {
        debugPrint(_compactStackTrace(stackTrace));
      }
      return;
    }

    // Release integration point for Firebase Crashlytics or equivalent.
    // Keep this method as the single app-wide crash reporting boundary.
  }

  static String _compactStackTrace(StackTrace stackTrace) {
    return stackTrace.toString().split('\n').take(8).join('\n');
  }
}
