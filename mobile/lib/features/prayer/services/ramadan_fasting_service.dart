import '../../../core/network/api_client.dart';
import '../models/ramadan_fasting_model.dart';

class RamadanFastingService {
  final ApiClient _apiClient;

  RamadanFastingService(this._apiClient);

  Future<RamadanFastingSummary> getTodaySummary() async {
    final response = await _apiClient.dio.get('/prayers/ramadan/fasting/today');
    return RamadanFastingSummary.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<RamadanFastingSummary> updateToday({
    required bool fasted,
    String fastType = 'ramadan',
    String? makeupForDate,
    String? note,
  }) async {
    final data = <String, dynamic>{'fasted': fasted, 'fast_type': fastType};
    if (makeupForDate != null) {
      data['makeup_for_date'] = makeupForDate;
    }
    if (note != null) {
      data['note'] = note;
    }
    final response = await _apiClient.dio.put(
      '/prayers/ramadan/fasting/today',
      data: data,
    );
    return RamadanFastingSummary.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
