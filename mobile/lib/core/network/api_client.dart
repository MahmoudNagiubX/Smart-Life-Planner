import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static const baseUrl = 'http://10.0.2.2:8000/api/v1';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}