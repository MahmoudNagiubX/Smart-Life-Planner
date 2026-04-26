import 'package:dio/dio.dart';

String friendlyApiError(Object error, String fallback) {
  if (error is! DioException) {
    return fallback;
  }

  final statusCode = error.response?.statusCode;
  final detail = _detailFromData(error.response?.data);

  if (_isConnectionProblem(error)) {
    return 'Network connection failed. Check your connection and try again.';
  }

  if (statusCode == 401) {
    return 'Please sign in again.';
  }
  if (statusCode == 403) {
    return 'You do not have access to this action.';
  }
  if (statusCode == 404) {
    return 'That item could not be found.';
  }
  if (statusCode == 409) {
    return _knownConflictMessage(detail) ??
        'This action conflicts with existing data.';
  }
  if (statusCode == 422) {
    return _validationMessage(error.response?.data) ??
        'Please check the submitted fields.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'Something went wrong on our side. Please try again.';
  }

  return _knownSafeMessage(detail) ?? fallback;
}

bool _isConnectionProblem(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError;
}

String? _detailFromData(dynamic data) {
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }
  if (data is String && data.isNotEmpty && !data.trim().startsWith('{')) {
    return data;
  }
  return null;
}

String? _validationMessage(dynamic data) {
  if (data is! Map) {
    return null;
  }
  final errors = data['errors'];
  if (errors is! List || errors.isEmpty) {
    return null;
  }

  return errors
      .map((item) {
        if (item is Map) {
          final field = item['field'];
          final message = item['message'];
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

String? _knownConflictMessage(String? detail) {
  final normalized = detail?.toLowerCase();
  if (normalized == null) return null;
  if (normalized.contains('already exists')) {
    return 'An item with this information already exists.';
  }
  if (normalized.contains('different sign-in') ||
      normalized.contains('original sign-in')) {
    return 'This account uses a different sign-in method.';
  }
  return null;
}

String? _knownSafeMessage(String? detail) {
  final normalized = detail?.toLowerCase();
  if (normalized == null) return null;
  if (normalized.contains('not found')) return 'That item could not be found.';
  if (normalized.contains('already completed')) {
    return 'This item is already completed.';
  }
  if (normalized.contains('not completed')) {
    return 'This item is not completed yet.';
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
