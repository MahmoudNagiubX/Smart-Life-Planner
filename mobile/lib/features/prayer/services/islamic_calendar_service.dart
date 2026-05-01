import '../../../core/network/api_client.dart';
import '../models/islamic_calendar_model.dart';

class IslamicCalendarService {
  final ApiClient _apiClient;

  IslamicCalendarService(this._apiClient);

  Future<IslamicCalendarModel> getCalendar() async {
    final response = await _apiClient.dio.get('/prayers/islamic-calendar');
    return IslamicCalendarModel.fromJson(response.data as Map<String, dynamic>);
  }
}
