import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

class ApiClient {
  static const _localhostBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const _androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return _androidEmulatorBaseUrl;
    }

    return _localhostBaseUrl;
  }

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
