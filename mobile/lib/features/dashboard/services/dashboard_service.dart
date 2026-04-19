import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<DashboardData> getHomeDashboard() async {
    final response = await _apiClient.dio.get('/dashboard/home');
    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  }
}