import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/focus_model.dart';
import '../services/focus_ambient_sound_service.dart';
import '../services/focus_service.dart';
import '../../tasks/providers/task_provider.dart';

final focusServiceProvider = Provider<FocusService>((ref) {
  return FocusService(ref.watch(apiClientProvider));
});

final focusAmbientSoundServiceProvider = Provider<FocusAmbientSoundService>((
  ref,
) {
  final service = FocusAmbientSoundService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

/// Algorithm: Finite State Machine
/// Used for: Focus session lifecycle and timer state.
/// Complexity: O(1) per transition; timer ticks update one counter.
/// Notes: Moves between idle, active focus, break, completed, and cancelled states.
class FocusState {
  final FocusSession? activeSession;
  final FocusAnalytics? analytics;
  final FocusRecommendation? recommendation;
  final FocusReadiness? readiness;
  final List<FocusSession> sessions;
  final bool isLoading;
  final bool isRecommendationLoading;
  final bool isReadinessLoading;
  final String? error;
  final String? recommendationError;
  final String? readinessError;
  final int remainingSeconds;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final bool continuousMode;
  final String ambientSoundKey;
  final bool distractionFreeMode;
  final FocusSession? lastCompletedSession;

  const FocusState({
    this.activeSession,
    this.analytics,
    this.recommendation,
    this.readiness,
    this.sessions = const [],
    this.isLoading = false,
    this.isRecommendationLoading = false,
    this.isReadinessLoading = false,
    this.error,
    this.recommendationError,
    this.readinessError,
    this.remainingSeconds = 0,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.continuousMode = false,
    this.ambientSoundKey = 'silence',
    this.distractionFreeMode = false,
    this.lastCompletedSession,
  });

  FocusState copyWith({
    FocusSession? activeSession,
    FocusAnalytics? analytics,
    FocusRecommendation? recommendation,
    FocusReadiness? readiness,
    List<FocusSession>? sessions,
    bool? isLoading,
    bool? isRecommendationLoading,
    bool? isReadinessLoading,
    String? error,
    String? recommendationError,
    String? readinessError,
    int? remainingSeconds,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    bool? continuousMode,
    String? ambientSoundKey,
    bool? distractionFreeMode,
    FocusSession? lastCompletedSession,
    bool clearSession = false,
  }) {
    return FocusState(
      activeSession: clearSession ? null : activeSession ?? this.activeSession,
      analytics: analytics ?? this.analytics,
      recommendation: recommendation ?? this.recommendation,
      readiness: readiness ?? this.readiness,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isRecommendationLoading:
          isRecommendationLoading ?? this.isRecommendationLoading,
      isReadinessLoading: isReadinessLoading ?? this.isReadinessLoading,
      error: error,
      recommendationError: recommendationError,
      readinessError: readinessError,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      continuousMode: continuousMode ?? this.continuousMode,
      ambientSoundKey: ambientSoundKey ?? this.ambientSoundKey,
      distractionFreeMode: distractionFreeMode ?? this.distractionFreeMode,
      lastCompletedSession: lastCompletedSession ?? this.lastCompletedSession,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final Ref _ref;
  Timer? _timer;
  Timer? _settingsSaveDebounce;

  FocusNotifier(this._ref) : super(const FocusState()) {
    _init();
  }

  Future<void> _init() async {
    await loadSettings();
    await loadAnalytics();
    await loadRecommendation();
    await loadReadiness();
    await _checkActiveSession();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _ref.read(focusServiceProvider).getSettings();
      state = state.copyWith(
        focusMinutes: settings.defaultFocusMinutes,
        shortBreakMinutes: settings.shortBreakMinutes,
        longBreakMinutes: settings.longBreakMinutes,
        sessionsBeforeLongBreak: settings.sessionsBeforeLongBreak,
        continuousMode: settings.continuousModeEnabled,
        ambientSoundKey: settings.ambientSoundKey,
        distractionFreeMode: settings.distractionFreeModeEnabled,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to load focus settings'),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to load focus settings');
    }
  }

  Future<void> _checkActiveSession() async {
    final service = _ref.read(focusServiceProvider);
    final session = await service.getActiveSession();
    if (session != null) {
      final startedAt = DateTime.parse(session.startedAt).toLocal();
      final endsAt = startedAt.add(Duration(minutes: session.plannedMinutes));
      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      final remaining = (session.plannedMinutes * 60 - elapsed).clamp(
        0,
        session.plannedMinutes * 60,
      );
      state = state.copyWith(
        activeSession: session,
        remainingSeconds: remaining,
      );
      if (remaining > 0) {
        await _ref
            .read(notificationSchedulerProvider)
            .scheduleFocusCompleteAt(
              sessionId: session.id,
              plannedMinutes: session.plannedMinutes,
              fireAt: endsAt,
            );
        _startTimer();
        await _syncAmbientSoundForSession(session);
      }
    }
  }

  Future<void> loadAnalytics() async {
    try {
      final service = _ref.read(focusServiceProvider);
      final analytics = await service.getAnalytics();
      final sessions = await service.getSessions();
      state = state.copyWith(analytics: analytics, sessions: sessions);
    } catch (_) {}
  }

  Future<void> loadRecommendation() async {
    state = state.copyWith(
      isRecommendationLoading: true,
      recommendationError: null,
    );
    try {
      final recommendation = await _ref
          .read(focusServiceProvider)
          .getRecommendation();
      state = state.copyWith(
        recommendation: recommendation,
        isRecommendationLoading: false,
        recommendationError: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isRecommendationLoading: false,
        recommendationError: friendlyApiError(
          e,
          'Failed to load focus recommendation',
        ),
      );
    } catch (_) {
      state = state.copyWith(
        isRecommendationLoading: false,
        recommendationError: 'Failed to load focus recommendation',
      );
    }
  }

  Future<void> loadReadiness() async {
    state = state.copyWith(isReadinessLoading: true, readinessError: null);
    try {
      final readiness = await _ref.read(focusServiceProvider).getReadiness();
      state = state.copyWith(
        readiness: readiness,
        isReadinessLoading: false,
        readinessError: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isReadinessLoading: false,
        readinessError: friendlyApiError(e, 'Failed to load focus readiness'),
      );
    } catch (_) {
      state = state.copyWith(
        isReadinessLoading: false,
        readinessError: 'Failed to load focus readiness',
      );
    }
  }

  void setFocusMinutes(int minutes) {
    state = state.copyWith(focusMinutes: minutes.clamp(5, 120));
    _queueSettingsSave();
  }

  void setShortBreakMinutes(int minutes) {
    state = state.copyWith(shortBreakMinutes: minutes.clamp(1, 30));
    _queueSettingsSave();
  }

  void setLongBreakMinutes(int minutes) {
    state = state.copyWith(longBreakMinutes: minutes.clamp(5, 60));
    _queueSettingsSave();
  }

  void setSessionsBeforeLongBreak(int sessions) {
    state = state.copyWith(sessionsBeforeLongBreak: sessions.clamp(1, 12));
    _queueSettingsSave();
  }

  void setContinuousMode(bool value) {
    state = state.copyWith(continuousMode: value);
    _queueSettingsSave();
  }

  void setAmbientSoundKey(String key) {
    state = state.copyWith(
      ambientSoundKey: FocusAmbientSoundService.normalizeKey(key),
    );
    _queueSettingsSave();
    unawaited(_syncAmbientSoundForSession(state.activeSession));
  }

  void setDistractionFreeMode(bool value) {
    state = state.copyWith(distractionFreeMode: value);
    _queueSettingsSave();
  }

  Future<void> startFocusSession({String? taskId}) {
    return startSession(
      plannedMinutes: state.focusMinutes,
      sessionType: 'pomodoro',
      taskId: taskId,
    );
  }

  Future<void> startRecommendedFocus() async {
    final recommendation = state.recommendation;
    if (recommendation == null || !recommendation.hasTask) return;
    await startSession(
      plannedMinutes: recommendation.recommendedDurationMinutes,
      sessionType: 'pomodoro',
      taskId: recommendation.taskId,
    );
  }

  Future<void> startBreakSession({required bool longBreak}) {
    return startSession(
      plannedMinutes: longBreak
          ? state.longBreakMinutes
          : state.shortBreakMinutes,
      sessionType: longBreak ? 'long_break' : 'short_break',
    );
  }

  Future<void> startSession({
    required int plannedMinutes,
    String sessionType = 'pomodoro',
    String? taskId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(focusServiceProvider);
      final session = await service.startSession(
        plannedMinutes: plannedMinutes,
        sessionType: sessionType,
        taskId: taskId,
      );

      // Schedule completion notification
      await _ref
          .read(notificationSchedulerProvider)
          .scheduleFocusComplete(
            sessionId: session.id,
            plannedMinutes: plannedMinutes,
          );

      state = state.copyWith(
        activeSession: session,
        isLoading: false,
        remainingSeconds: plannedMinutes * 60,
      );
      _startTimer();
      await _syncAmbientSoundForSession(session);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to start session'),
      );
    }
  }

  Future<void> completeSession({bool cancelNotification = true}) async {
    final session = state.activeSession;
    if (session == null) return;
    _timer?.cancel();
    await _stopAmbientSound();

    if (cancelNotification) {
      // Cancel the scheduled notification only when the user finishes manually.
      await _ref
          .read(notificationSchedulerProvider)
          .cancelFocusNotification(session.id);
    }

    try {
      final service = _ref.read(focusServiceProvider);
      final completed = await service.completeSession(session.id);
      final shouldContinue = state.continuousMode;
      state = state.copyWith(
        clearSession: true,
        remainingSeconds: 0,
        lastCompletedSession: completed,
      );
      if (completed.taskId != null) {
        await _ref.read(tasksProvider.notifier).loadTasks();
      }
      await loadAnalytics();
      await loadRecommendation();
      await loadReadiness();
      if (shouldContinue) {
        if (_isBreakSession(completed.sessionType)) {
          await startFocusSession();
        } else {
          await startBreakSession(longBreak: _shouldStartLongBreak(completed));
        }
      }
    } catch (_) {}
  }

  Future<void> skipBreak() async {
    final session = state.activeSession;
    if (session == null || !_isBreakSession(session.sessionType)) return;
    final shouldContinue = state.continuousMode;
    await cancelSession();
    if (shouldContinue) {
      await startFocusSession();
    }
  }

  Future<void> cancelSession() async {
    final session = state.activeSession;
    if (session == null) return;
    _timer?.cancel();
    await _stopAmbientSound();

    // Cancel the scheduled notification
    await _ref
        .read(notificationSchedulerProvider)
        .cancelFocusNotification(session.id);

    try {
      final service = _ref.read(focusServiceProvider);
      await service.cancelSession(session.id);
      state = state.copyWith(clearSession: true, remainingSeconds: 0);
      await loadAnalytics();
      await loadRecommendation();
      await loadReadiness();
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        timer.cancel();
        completeSession(cancelNotification: false);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  bool _isBreakSession(String sessionType) {
    return sessionType == 'short_break' || sessionType == 'long_break';
  }

  Future<void> _syncAmbientSoundForSession(FocusSession? session) async {
    final soundService = _ref.read(focusAmbientSoundServiceProvider);
    if (session == null || _isBreakSession(session.sessionType)) {
      await soundService.stop();
      return;
    }
    await soundService.play(state.ambientSoundKey);
  }

  Future<void> _stopAmbientSound() {
    return _ref.read(focusAmbientSoundServiceProvider).stop();
  }

  /// Algorithm: Modular Counting
  /// Used for: Deciding when a Pomodoro cycle should start a long break.
  /// Complexity: O(n) over completed sessions in memory.
  /// Notes: Every N completed focus sessions triggers a long break.
  bool _shouldStartLongBreak(FocusSession completed) {
    if (_isBreakSession(completed.sessionType)) return false;
    final completedFocusIds = state.sessions
        .where(
          (session) =>
              session.status == 'completed' &&
              !_isBreakSession(session.sessionType),
        )
        .map((session) => session.id)
        .toSet();
    completedFocusIds.add(completed.id);
    return completedFocusIds.length % state.sessionsBeforeLongBreak == 0;
  }

  void _queueSettingsSave() {
    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(saveSettings()),
    );
  }

  Future<void> saveSettings() async {
    try {
      final settings = FocusSettings(
        defaultFocusMinutes: state.focusMinutes,
        shortBreakMinutes: state.shortBreakMinutes,
        longBreakMinutes: state.longBreakMinutes,
        sessionsBeforeLongBreak: state.sessionsBeforeLongBreak,
        continuousModeEnabled: state.continuousMode,
        ambientSoundKey: state.ambientSoundKey,
        distractionFreeModeEnabled: state.distractionFreeMode,
      );
      final saved = await _ref
          .read(focusServiceProvider)
          .updateSettings(settings);
      state = state.copyWith(
        focusMinutes: saved.defaultFocusMinutes,
        shortBreakMinutes: saved.shortBreakMinutes,
        longBreakMinutes: saved.longBreakMinutes,
        sessionsBeforeLongBreak: saved.sessionsBeforeLongBreak,
        continuousMode: saved.continuousModeEnabled,
        ambientSoundKey: saved.ambientSoundKey,
        distractionFreeMode: saved.distractionFreeModeEnabled,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: friendlyApiError(e, 'Failed to save focus settings'),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to save focus settings');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settingsSaveDebounce?.cancel();
    unawaited(_stopAmbientSound());
    super.dispose();
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier(ref);
});
