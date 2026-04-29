import '../../../core/network/api_client.dart';
import '../models/app_settings_model.dart';

class AppSettingsService {
  final ApiClient _apiClient;

  const AppSettingsService(this._apiClient);

  Future<AppSettingsModel> getSettings() async {
    final response = await _apiClient.dio.get('/settings');
    return AppSettingsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppSettingsModel> updateSettings({
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
    final data = <String, dynamic>{};
    if (language != null) data['language'] = language;
    if (theme != null) data['theme'] = theme;
    if (notificationsEnabled != null) {
      data['notifications_enabled'] = notificationsEnabled;
    }
    if (country != null) data['country'] = country;
    if (city != null) data['city'] = city;
    if (timezone != null) data['timezone'] = timezone;
    if (wakeTime != null) data['wake_time'] = wakeTime;
    if (sleepTime != null) data['sleep_time'] = sleepTime;
    if (microphoneEnabled != null) {
      data['microphone_enabled'] = microphoneEnabled;
    }
    if (locationEnabled != null) data['location_enabled'] = locationEnabled;

    final response = await _apiClient.dio.patch('/settings', data: data);
    return AppSettingsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
