import '../../../core/network/api_client.dart';
import '../models/reminder_preferences_model.dart';

class ReminderPreferencesResult {
  final bool notificationsEnabled;
  final ReminderPreferences preferences;

  const ReminderPreferencesResult({
    required this.notificationsEnabled,
    required this.preferences,
  });
}

class ReminderPreferencesService {
  final ApiClient _apiClient;

  ReminderPreferencesService(this._apiClient);

  Future<ReminderPreferencesResult> getPreferences() async {
    final response = await _apiClient.dio.get('/settings');
    final data = response.data as Map<String, dynamic>;
    return ReminderPreferencesResult(
      notificationsEnabled: data['notifications_enabled'] as bool? ?? true,
      preferences: ReminderPreferences.fromJson(
        data['reminder_preferences'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Future<ReminderPreferencesResult> updatePreferences({
    bool? notificationsEnabled,
    ReminderPreferences? preferences,
  }) async {
    final data = <String, dynamic>{};
    if (notificationsEnabled != null) {
      data['notifications_enabled'] = notificationsEnabled;
    }
    if (preferences != null) {
      data['reminder_preferences'] = preferences.toJson();
    }

    final response = await _apiClient.dio.patch('/settings', data: data);
    final body = response.data as Map<String, dynamic>;
    return ReminderPreferencesResult(
      notificationsEnabled: body['notifications_enabled'] as bool? ?? true,
      preferences: ReminderPreferences.fromJson(
        body['reminder_preferences'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
