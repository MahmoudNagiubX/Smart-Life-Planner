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
          normalized.contains('original sign-in method')) {
        return 'This account uses a social sign-in method.';
      }
      if (normalized.contains('already exists')) {
        return 'An account with this email already exists.';
      }
      if (normalized.contains('different sign-in') ||
          normalized.contains('another google sign-in')) {
        return 'This account uses a different sign-in method.';
      }
      if (statusCode == 422) {
        return _validationMessage(data) ??
            'Please check the highlighted fields.';
      }
      return _knownSafeMessage(detail) ?? fallback;
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
          if (message is! String) return null;
          if (field is String && field == 'sensitive_field') {
            return 'Please check one of the submitted fields.';
          }
          if (field is String) return '$field: ${_friendlyValidation(message)}';
          return _friendlyValidation(message);
        }
        return null;
      })
      .whereType<String>()
      .join('\n');
}

String? _knownSafeMessage(String detail) {
  final normalized = detail.toLowerCase();
  if (normalized.contains('invalid code')) {
    return 'That code is invalid or expired.';
  }
  if (normalized.contains('please wait')) {
    return 'Please wait before trying again.';
  }
  if (normalized.contains('not configured')) {
    return 'This sign-in method is not configured yet.';
  }
  return null;
}

String _friendlyValidation(String message) {
  final normalized = message.toLowerCase();
  if (normalized.contains('field required')) return 'This field is required.';
  if (normalized.contains('valid email')) return 'Enter a valid email address.';
  if (normalized.contains('at least 8')) return 'Use at least 8 characters.';
  if (normalized.contains('6-digit')) return 'Enter the 6-digit code.';
  return 'Please check this value.';
}
