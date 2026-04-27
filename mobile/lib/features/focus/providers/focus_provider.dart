import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../models/focus_model.dart';
import '../services/focus_service.dart';

final focusServiceProvider = Provider<FocusService>((ref) {
  return FocusService(ref.watch(apiClientProvider));
});

class FocusState {
  final FocusSession? activeSession;
  final FocusAnalytics? analytics;
  final List<FocusSession> sessions;
  final bool isLoading;
  final String? error;
  final int remainingSeconds;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool continuousMode;
  final bool distractionFreeMode;
  final FocusSession? lastCompletedSession;

  const FocusState({
    this.activeSession,
    this.analytics,
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.remainingSeconds = 0,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.continuousMode = false,
    this.distractionFreeMode = false,
    this.lastCompletedSession,
  });

  FocusState copyWith({
    FocusSession? activeSession,
    FocusAnalytics? analytics,
    List<FocusSession>? sessions,
    bool? isLoading,
    String? error,
    int? remainingSeconds,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? continuousMode,
    bool? distractionFreeMode,
    FocusSession? lastCompletedSession,
    bool clearSession = false,
  }) {
    return FocusState(
      activeSession: clearSession ? null : activeSession ?? this.activeSession,
      analytics: analytics ?? this.analytics,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      continuousMode: continuousMode ?? this.continuousMode,
      distractionFreeMode: distractionFreeMode ?? this.distractionFreeMode,
      lastCompletedSession: lastCompletedSession ?? this.lastCompletedSession,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final Ref _ref;
  Timer? _timer;

  FocusNotifier(this._ref) : super(const FocusState()) {
    _init();
  }

  Future<void> _init() async {
    await loadAnalytics();
    await _checkActiveSession();
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

  void setFocusMinutes(int minutes) {
    state = state.copyWith(focusMinutes: minutes.clamp(5, 120));
  }

  void setShortBreakMinutes(int minutes) {
    state = state.copyWith(shortBreakMinutes: minutes.clamp(1, 30));
  }

  void setLongBreakMinutes(int minutes) {
    state = state.copyWith(longBreakMinutes: minutes.clamp(5, 60));
  }

  void setContinuousMode(bool value) {
    state = state.copyWith(continuousMode: value);
  }

  void setDistractionFreeMode(bool value) {
    state = state.copyWith(distractionFreeMode: value);
  }

  Future<void> startFocusSession({String? taskId}) {
    return startSession(
      plannedMinutes: state.focusMinutes,
      sessionType: 'pomodoro',
      taskId: taskId,
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
      await loadAnalytics();
      if (shouldContinue) {
        if (_isBreakSession(completed.sessionType)) {
          await startFocusSession();
        } else {
          await startBreakSession(longBreak: false);
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

    // Cancel the scheduled notification
    await _ref
        .read(notificationSchedulerProvider)
        .cancelFocusNotification(session.id);

    try {
      final service = _ref.read(focusServiceProvider);
      await service.cancelSession(session.id);
      state = state.copyWith(clearSession: true, remainingSeconds: 0);
      await loadAnalytics();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier(ref);
});
