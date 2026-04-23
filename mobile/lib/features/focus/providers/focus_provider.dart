import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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

  const FocusState({
    this.activeSession,
    this.analytics,
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.remainingSeconds = 0,
  });

  FocusState copyWith({
    FocusSession? activeSession,
    FocusAnalytics? analytics,
    List<FocusSession>? sessions,
    bool? isLoading,
    String? error,
    int? remainingSeconds,
    bool clearSession = false,
  }) {
    return FocusState(
      activeSession: clearSession ? null : activeSession ?? this.activeSession,
      analytics: analytics ?? this.analytics,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
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
      final remaining =
          (session.plannedMinutes * 60 - elapsed).clamp(0, session.plannedMinutes * 60);
      state = state.copyWith(
        activeSession: session,
        remainingSeconds: remaining,
      );
      if (remaining > 0) {
        await _ref.read(notificationSchedulerProvider).scheduleFocusCompleteAt(
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

  Future<void> startSession({
    required int plannedMinutes,
    String sessionType = 'pomodoro',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(focusServiceProvider);
      final session = await service.startSession(
        plannedMinutes: plannedMinutes,
        sessionType: sessionType,
      );

      // Schedule completion notification
      await _ref.read(notificationSchedulerProvider).scheduleFocusComplete(
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
        error: e.response?.data['detail'] as String? ?? 'Failed to start session',
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
      await service.completeSession(session.id);
      state = state.copyWith(clearSession: true, remainingSeconds: 0);
      await loadAnalytics();
    } catch (_) {}
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
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );
      }
    });
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
