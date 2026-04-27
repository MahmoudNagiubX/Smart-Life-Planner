import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/ramadan_settings_model.dart';
import '../services/ramadan_settings_service.dart';

final ramadanSettingsServiceProvider = Provider<RamadanSettingsService>((ref) {
  return RamadanSettingsService(ref.watch(apiClientProvider));
});

class RamadanSettingsState {
  final RamadanSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const RamadanSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  RamadanSettingsState copyWith({
    RamadanSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return RamadanSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class RamadanSettingsNotifier extends StateNotifier<RamadanSettingsState> {
  final Ref _ref;

  RamadanSettingsNotifier(this._ref) : super(const RamadanSettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = _ref.read(ramadanSettingsServiceProvider);
      final settings = await service.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load Ramadan settings'),
      );
    }
  }

  Future<void> updateSettings({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final service = _ref.read(ramadanSettingsServiceProvider);
      final settings = await service.updateSettings(
        ramadanModeEnabled: ramadanModeEnabled,
        suhoorReminderEnabled: suhoorReminderEnabled,
        suhoorReminderMinutesBeforeFajr: suhoorReminderMinutesBeforeFajr,
      );
      state = state.copyWith(settings: settings, isSaving: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to update Ramadan settings'),
      );
    }
  }
}

final ramadanSettingsProvider =
    StateNotifierProvider<RamadanSettingsNotifier, RamadanSettingsState>((ref) {
      return RamadanSettingsNotifier(ref);
    });
