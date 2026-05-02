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

  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/verify-email',
      data: {'email': email, 'code': code},
    );
    return response.data['message'] as String? ?? 'Email verified';
  }

  Future<String> resendVerification({required String email}) async {
    final response = await _apiClient.dio.post(
      '/auth/resend-verification',
      data: {'email': email},
    );
    return _messageWithDevelopmentCode(
      response.data,
      fallback: 'Verification code sent',
    );
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _apiClient.dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return _messageWithDevelopmentCode(
      response.data,
      fallback: 'Reset code sent',
    );
  }

  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );
    return response.data['reset_token'] as String;
  }

  Future<String> setNewPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/set-new-password',
      data: {'reset_token': resetToken, 'new_password': newPassword},
    );
    return response.data['message'] as String? ?? 'Password updated';
  }

  Future<String> googleSignIn({required String idToken}) async {
    final response = await _apiClient.dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    return response.data['access_token'] as String;
  }

  /// Send Apple identity token to the backend for verification.
  ///
  /// [identityToken] — JWT from Apple's identity server.
  /// [fullName]      — Only present on the very first Apple sign-in.
  /// [email]         — May be a private relay address; only on first sign-in.
  Future<String> appleSignIn({
    required String identityToken,
    String? fullName,
    String? email,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/apple',
      data: {
        'identity_token': identityToken,
        'full_name': fullName,
        'email': email,
      }..removeWhere((_, v) => v == null),
    );
    return response.data['access_token'] as String;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.dio.get('/auth/me');
    return response.data;
  }

  Future<void> deleteAccount({String? password, String? confirmation}) async {
    await _apiClient.dio.delete(
      '/auth/delete-account',
      data: {'password': password, 'confirmation': confirmation}
        ..removeWhere((_, v) => v == null),
    );
  }

  String _messageWithDevelopmentCode(dynamic data, {required String fallback}) {
    if (data is! Map<String, dynamic>) return fallback;
    final message = data['message'] as String? ?? fallback;
    final code = data['development_code'] as String?;
    if (code == null || code.isEmpty) return message;
    return '$message Code: $code';
  }
}
