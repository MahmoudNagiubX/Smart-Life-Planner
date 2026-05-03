import '../../../core/network/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final ApiClient _apiClient;

  ScheduleService(this._apiClient);

  Future<DailyScheduleModel> getSchedule({String? date}) async {
    final response = await _apiClient.dio.get(
      '/scheduling/schedule',
      queryParameters: {
        'schedule_date': date,
      }..removeWhere((_, value) => value == null),
    );
    return DailyScheduleModel.fromJson(response.data as Map<String, dynamic>);
  }
}
