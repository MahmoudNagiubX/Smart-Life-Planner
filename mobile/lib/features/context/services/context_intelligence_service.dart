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

  Future<TimeContextRecommendationResult> getRecommendations({
    String? timeBlock,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (timeBlock != null) {
      queryParameters['time_block'] = timeBlock;
    }
    final response = await _apiClient.dio.get(
      '/context/recommendations',
      queryParameters: queryParameters,
    );
    return TimeContextRecommendationResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ContextTaskRecommendationResult> getTaskRecommendations({
    String? timeBlock,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (timeBlock != null) {
      queryParameters['time_block'] = timeBlock;
    }
    final response = await _apiClient.dio.get(
      '/context/task-recommendations',
      queryParameters: queryParameters,
    );
    return ContextTaskRecommendationResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
