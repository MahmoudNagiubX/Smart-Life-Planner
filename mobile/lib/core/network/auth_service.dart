import '../network/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/register',
      data: {'email': email, 'full_name': fullName, 'password': password},
    );
    return response.data;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data['access_token'];
  }

  Future<String> googleSignIn({required String idToken}) async {
    final response = await _apiClient.dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    return response.data['access_token'] as String;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.dio.get('/auth/me');
    return response.data;
  }
}
