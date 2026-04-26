import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_data.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../features/auth/providers/auth_provider.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingData());

  void updateData(OnboardingData newData) {
    state = newData;
  }

  void update(OnboardingData Function(OnboardingData current) update) {
    state = update(state);
  }

  Future<bool> submitOnboarding() async {
    if (!state.hasRequiredSelections) {
      return false;
    }

    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.post('/settings/onboarding', data: state.toJson());
      await _ref.read(notificationSchedulerProvider).cancelAllPrayerReminders();
      await _ref.read(authProvider.notifier).refreshUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
      return OnboardingNotifier(ref);
    });
