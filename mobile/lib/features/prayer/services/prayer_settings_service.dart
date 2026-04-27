import '../../../core/network/api_client.dart';
import '../models/prayer_settings_model.dart';

class PrayerSettingsService {
  final ApiClient _apiClient;

  PrayerSettingsService(this._apiClient);

  Future<PrayerSettings> getSettings() async {
    final response = await _apiClient.dio.get('/settings');
    return PrayerSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PrayerSettings> updateSettings({
    String? prayerCalculationMethod,
    double? prayerLocationLat,
    double? prayerLocationLng,
    String? city,
    int? prayerReminderMinutesBefore,
    bool? athanSoundEnabled,
    bool? ramadanModeEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (prayerCalculationMethod != null) {
      data['prayer_calculation_method'] = prayerCalculationMethod;
    }
    if (prayerLocationLat != null) {
      data['prayer_location_lat'] = prayerLocationLat;
    }
    if (prayerLocationLng != null) {
      data['prayer_location_lng'] = prayerLocationLng;
    }
    if (city != null) {
      data['city'] = city;
    }
    if (prayerReminderMinutesBefore != null) {
      data['prayer_reminder_minutes_before'] = prayerReminderMinutesBefore;
    }
    if (athanSoundEnabled != null) {
      data['athan_sound_enabled'] = athanSoundEnabled;
    }
    if (ramadanModeEnabled != null) {
      data['ramadan_mode_enabled'] = ramadanModeEnabled;
    }

    final response = await _apiClient.dio.patch('/settings', data: data);
    return PrayerSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
