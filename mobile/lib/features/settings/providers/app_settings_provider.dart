import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/providers.dart';
import '../models/app_settings_model.dart';
import '../services/app_settings_service.dart';

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  return AppSettingsService(ref.watch(apiClientProvider));
});

class AppSettingsState {
  final AppSettingsModel? settings;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? error;

  const AppSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.error,
  });

  AppSettingsState copyWith({
    AppSettingsModel? settings,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    String? error,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final Ref _ref;

  AppSettingsNotifier(this._ref) : super(const AppSettingsState());

  Future<void> loadSettings({bool force = false}) async {
    if (!force && state.hasLoaded) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _ref
          .read(appSettingsServiceProvider)
          .getSettings();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        hasLoaded: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyApiError(e, 'Failed to load settings'),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings',
      );
    }
  }

  Future<bool> saveSettings({
    String? language,
    String? theme,
    bool? notificationsEnabled,
    String? country,
    String? city,
    String? timezone,
    String? wakeTime,
    String? sleepTime,
    bool? microphoneEnabled,
    bool? locationEnabled,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final settings = await _ref
          .read(appSettingsServiceProvider)
          .updateSettings(
            language: language,
            theme: theme,
            notificationsEnabled: notificationsEnabled,
            country: country,
            city: city,
            timezone: timezone,
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            microphoneEnabled: microphoneEnabled,
            locationEnabled: locationEnabled,
          );
      state = state.copyWith(
        settings: settings,
        isSaving: false,
        hasLoaded: true,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: friendlyApiError(e, 'Failed to save settings'),
      );
      return false;
    } catch (_) {
      state = state.copyWith(isSaving: false, error: 'Failed to save settings');
      return false;
    }
  }

  void reset() {
    state = const AppSettingsState();
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
      return AppSettingsNotifier(ref);
    });
