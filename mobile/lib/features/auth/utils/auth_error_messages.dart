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
      if (normalized.contains('already registered')) {
        return 'An account with this email already exists. Sign in or reset your password.';
      }
      if (normalized.contains('different sign-in') ||
          normalized.contains('another google sign-in')) {
        return 'This account uses a different sign-in method.';
      }
      if (normalized.contains('invalid google token') ||
          normalized.contains('web oauth client id')) {
        return 'Google sign-in is configured incorrectly. Check the Web OAuth client ID on Android and the backend GOOGLE_CLIENT_ID.';
      }
      if (normalized.contains('email delivery') ||
          normalized.contains('could not send email')) {
        return 'Email sending is not configured yet. Check backend email settings or use the development code.';
      }
      if (normalized.contains('at least 8')) {
        return 'Use a password with at least 8 characters.';
      }
      if (normalized.contains('full name')) {
        return 'Enter your full name.';
      }
      if (normalized.contains('valid email') ||
          normalized.contains('email address')) {
        return 'Enter a valid email address.';
      }
      if (normalized.contains('google sign-in not configured')) {
        return 'Google Sign-In is not configured correctly. Check Web Client ID, Android package name, and SHA-1/SHA-256 fingerprints.';
      }
      if (normalized.contains('google-auth dependency') ||
          normalized.contains('google sign-in is not available')) {
        return 'Google Sign-In is not available on the backend. Install the google-auth dependency and restart the server.';
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
    if (detail is List && detail.isNotEmpty) {
      return detail
          .map((item) {
            if (item is Map) {
              final message = item['msg'] ?? item['message'];
              return message is String ? message : null;
            }
            return null;
          })
          .whereType<String>()
          .join('\n');
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

String? _validationMessage(dynamic data) {
  if (data is! Map) return null;
  final errors = data['errors'];
  final detail = data['detail'];
  final items = errors is List
      ? errors
      : detail is List
      ? detail
      : null;
  if (items == null || items.isEmpty) return null;
  return items
      .map((item) {
        if (item is Map) {
          final loc = item['loc'];
          final field =
              item['field'] ??
              (loc is List && loc.isNotEmpty ? loc.last.toString() : null);
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
