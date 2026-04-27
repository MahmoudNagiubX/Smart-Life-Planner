import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/prayer_settings_model.dart';
import '../services/prayer_settings_service.dart';

final prayerSettingsServiceProvider = Provider<PrayerSettingsService>((ref) {
  return PrayerSettingsService(ref.watch(apiClientProvider));
});

class PrayerSettingsState {
  final PrayerSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const PrayerSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  PrayerSettingsState copyWith({
    PrayerSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return PrayerSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class PrayerSettingsNotifier extends StateNotifier<PrayerSettingsState> {
  final Ref _ref;

  PrayerSettingsNotifier(this._ref) : super(const PrayerSettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(prayerSettingsServiceProvider);
      final settings = await service.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load prayer settings'),
      );
    }
  }

  Future<void> updateSettings({
    String? prayerCalculationMethod,
    double? prayerLocationLat,
    double? prayerLocationLng,
    String? city,
    int? prayerReminderMinutesBefore,
    bool? athanSoundEnabled,
    bool? ramadanModeEnabled,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(prayerSettingsServiceProvider);
      final settings = await service.updateSettings(
        prayerCalculationMethod: prayerCalculationMethod,
        prayerLocationLat: prayerLocationLat,
        prayerLocationLng: prayerLocationLng,
        city: city,
        prayerReminderMinutesBefore: prayerReminderMinutesBefore,
        athanSoundEnabled: athanSoundEnabled,
        ramadanModeEnabled: ramadanModeEnabled,
      );
      state = state.copyWith(settings: settings, isSaving: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update prayer settings'),
      );
    }
  }
}

final prayerSettingsProvider =
    StateNotifierProvider<PrayerSettingsNotifier, PrayerSettingsState>((ref) {
      return PrayerSettingsNotifier(ref);
    });
