import '../../../core/network/api_client.dart';
import '../models/context_intelligence_model.dart';

class ContextIntelligenceService {
  final ApiClient _apiClient;

  ContextIntelligenceService(this._apiClient);

  Future<ContextIntelligenceSnapshot> getSnapshot() async {
    final response = await _apiClient.dio.get('/context/snapshot');
    return ContextIntelligenceSnapshot.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ContextIntelligenceSnapshot> createSnapshot(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.dio.post(
      '/context/snapshot',
      data: payload,
    );
    return ContextIntelligenceSnapshot.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
