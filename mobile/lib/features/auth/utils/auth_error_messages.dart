import 'package:dio/dio.dart';

String friendlyAuthError(Object error, String fallback) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final detail = _detailFromData(data);

    if (detail != null) {
      final normalized = detail.toLowerCase();
      if (normalized.contains('invalid credentials')) {
        return 'The email or password is incorrect.';
      }
      if (normalized.contains('verify your email') ||
          normalized.contains('unverified')) {
        return 'Please verify your email before signing in.';
      }
      if (normalized.contains('expired code') ||
          normalized.contains('expired reset token')) {
        return 'That code expired. Request a new one and try again.';
      }
      if (normalized.contains('social sign-in') ||
          normalized.contains('original sign-in method') ||
          normalized.contains('already exists')) {
        return detail;
      }
      if (statusCode == 422) {
        return _validationMessage(data) ??
            'Please check the highlighted fields.';
      }
      return detail;
    }

    if (statusCode == 401) return 'Please sign in again.';
    if (statusCode == 403) return 'You do not have access to this action.';
    if (statusCode == 409) {
      return 'This account uses a different sign-in method.';
    }
    if (statusCode == 429) return 'Please wait before trying again.';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Network connection failed. Check your internet and try again.';
    }
  }

  return fallback;
}

String? _detailFromData(dynamic data) {
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

String? _validationMessage(dynamic data) {
  if (data is! Map) return null;
  final errors = data['errors'];
  if (errors is! List || errors.isEmpty) return null;
  return errors
      .map((item) {
        if (item is Map) {
          final field = item['field'];
          final message = item['message'] ?? item['msg'];
          if (field is String && message is String) return '$field: $message';
          if (message is String) return message;
        }
        return item.toString();
      })
      .join('\n');
}
