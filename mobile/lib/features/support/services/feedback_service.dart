import '../../../core/network/api_client.dart';

class FeedbackService {
  final ApiClient _apiClient;

  const FeedbackService(this._apiClient);

  Future<String> submitFeedback({
    required String category,
    required String message,
    String appVersion = '1.0.0+1',
    String deviceContext = 'Flutter mobile app',
  }) async {
    final response = await _apiClient.dio.post(
      '/support/feedback',
      data: {
        'category': category,
        'message': message,
        'app_version': appVersion,
        'device_context': deviceContext,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Feedback received';
  }
}
