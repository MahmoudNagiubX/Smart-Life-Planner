import '../../../core/network/api_client.dart';
import '../models/prayer_model.dart';

class PrayerService {
  final ApiClient _apiClient;

  PrayerService(this._apiClient);

  Future<DailyPrayers> getTodayPrayers() async {
    final response = await _apiClient.dio.get('/prayers/today');
    return DailyPrayers.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> completePrayer(String prayerName, String date) async {
    await _apiClient.dio.patch('/prayers/$prayerName/$date/complete');
  }

  Future<void> uncompletePrayer(String prayerName, String date) async {
    await _apiClient.dio.patch('/prayers/$prayerName/$date/uncomplete');
  }
}