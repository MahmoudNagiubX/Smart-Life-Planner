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
    return detail ?? 'This action conflicts with existing data.';
  }
  if (statusCode == 422) {
    return _validationMessage(error.response?.data) ??
        detail ??
        'Please check the submitted fields.';
  }
  if (statusCode != null && statusCode >= 500) {
    return 'Something went wrong on our side. Please try again.';
  }

  return detail ?? fallback;
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
          if (field is String && message is String) return '$field: $message';
          if (message is String) return message;
        }
        return null;
      })
      .whereType<String>()
      .join('\n');
}
