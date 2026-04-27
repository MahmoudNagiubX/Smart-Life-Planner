import '../../../core/network/api_client.dart';
import '../models/ramadan_settings_model.dart';

class RamadanSettingsService {
  final ApiClient _apiClient;

  RamadanSettingsService(this._apiClient);

  Future<RamadanSettings> getSettings() async {
    final response = await _apiClient.dio.get('/settings');
    return RamadanSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RamadanSettings> updateSettings({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
  }) async {
    final data = <String, dynamic>{};
    if (ramadanModeEnabled != null) {
      data['ramadan_mode_enabled'] = ramadanModeEnabled;
    }
    if (suhoorReminderEnabled != null) {
      data['suhoor_reminder_enabled'] = suhoorReminderEnabled;
    }
    if (suhoorReminderMinutesBeforeFajr != null) {
      data['suhoor_reminder_minutes_before_fajr'] =
          suhoorReminderMinutesBeforeFajr;
    }

    final response = await _apiClient.dio.patch('/settings', data: data);
    return RamadanSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
