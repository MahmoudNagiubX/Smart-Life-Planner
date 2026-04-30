import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/core/network/api_error.dart';
import 'package:smart_life_planner/features/auth/utils/auth_error_messages.dart';

void main() {
  DioException dioError({required int statusCode, required Object data}) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  test('friendly API errors do not expose raw backend detail', () {
    final message = friendlyApiError(
      dioError(
        statusCode: 500,
        data: {'detail': 'Traceback: password token secret'},
      ),
      'Fallback',
    );

    expect(message, 'Something went wrong on our side. Please try again.');
  });

  test('friendly API validation hides sensitive field names', () {
    final message = friendlyApiError(
      dioError(
        statusCode: 422,
        data: {
          'errors': [
            {'field': 'sensitive_field', 'message': 'Field required'},
          ],
        },
      ),
      'Fallback',
    );

    expect(message, 'Please check one of the submitted fields.');
  });

  test('friendly auth errors map raw backend detail to stable UX copy', () {
    final message = friendlyAuthError(
      dioError(
        statusCode: 409,
        data: {
          'detail':
              'An account with this email already exists. Please sign in with email/password.',
        },
      ),
      'Fallback',
    );

    expect(message, 'An account with this email already exists.');
  });

  test('friendly API errors read structured safe detail message', () {
    final message = friendlyApiError(
      dioError(
        statusCode: 400,
        data: {
          'detail': {
            'code': 'smart_note_empty_content',
            'message': 'Add note content before summarizing.',
            'manual_fallback': 'Write a manual summary in the note editor.',
          },
        },
      ),
      'Failed to summarize note',
    );

    expect(message, 'Add note content before summarizing.');
  });
}
