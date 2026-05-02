import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../utils/auth_error_messages.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '518693074192-uohabck566gvtocahd8pfrctqorujmnc.apps.googleusercontent.com',
  );

  final Ref _ref;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _googleServerClientId,
  );

  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    try {
      final hasToken = await tokenStorage.hasToken();
      if (hasToken) {
        final authService = _ref.read(authServiceProvider);
        final user = await authService.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      await tokenStorage.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> refreshUser() async {
    final authService = _ref.read(authServiceProvider);
    final user = await authService.getMe();
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      error: null,
    );
  }

  Future<String?> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      state = state.copyWith(error: null);
      final authService = _ref.read(authServiceProvider);
      final message = await authService.register(
        email: email,
        fullName: fullName,
        password: password,
      );
      state = const AuthState(status: AuthStatus.unauthenticated);
      return message;
    } on DioException catch (e) {
      final message = _authDioError(e, 'Registration failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      state = state.copyWith(error: null);
      final authService = _ref.read(authServiceProvider);
      final tokenStorage = _ref.read(tokenStorageProvider);
      final token = await authService.login(email: email, password: password);
      await tokenStorage.saveToken(token);
      final user = await authService.getMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } on DioException catch (e) {
      await _ref.read(tokenStorageProvider).deleteToken();
      final message = _authDioError(e, 'Login failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  Future<void> googleLogin() async {
    try {
      state = state.copyWith(error: null);
      if (_googleServerClientId.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error:
              'Google sign-in is missing GOOGLE_CLIENT_ID. Configure the Web OAuth client ID for Android.',
        );
        return;
      }

      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error:
              'Google sign-in did not return an ID token. Check the Google web client ID.',
        );
        return;
      }

      final authService = _ref.read(authServiceProvider);
      final tokenStorage = _ref.read(tokenStorageProvider);

      final token = await authService.googleSignIn(idToken: idToken);
      await tokenStorage.saveToken(token);

      final user = await authService.getMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } on DioException catch (e) {
      await _ref.read(tokenStorageProvider).deleteToken();
      final message = _authDioError(e, 'Google sign-in failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    } on PlatformException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _googlePlatformError(e),
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('api exception: 10') ||
          message.contains('sign_in_failed')) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error:
              'Google Sign-In is not configured correctly. Check Web Client ID, Android package name, and SHA-1/SHA-256 fingerprints.',
        );
        return;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Google sign-in failed. Please try again.',
      );
    }
  }

  /// Sign in with Apple.
  ///
  /// Only available on iOS/macOS natively. On Android the package shows
  /// a web-based flow. We guard the button in the UI instead.
  ///
  /// Apple only sends [fullName] and [email] on the VERY FIRST sign-in.
  /// We always pass them in the payload so the backend can cache them.
  Future<void> appleSignIn() async {
    try {
      state = state.copyWith(error: null);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Apple sign-in did not return an identity token.',
        );
        return;
      }

      // Build optional name from the credential (first sign-in only)
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      String? fullName;
      if (givenName != null || familyName != null) {
        fullName = [givenName, familyName].whereType<String>().join(' ').trim();
        if (fullName.isEmpty) fullName = null;
      }

      final authService = _ref.read(authServiceProvider);
      final tokenStorage = _ref.read(tokenStorageProvider);

      final token = await authService.appleSignIn(
        identityToken: identityToken,
        fullName: fullName,
        email: credential.email,
      );
      await tokenStorage.saveToken(token);

      final user = await authService.getMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } on DioException catch (e) {
      await _ref.read(tokenStorageProvider).deleteToken();
      final message = _authDioError(e, 'Apple sign-in failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled — not an error
      if (e.code == AuthorizationErrorCode.canceled) return;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Apple sign-in failed: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Apple sign-in failed: $e',
      );
    }
  }

  Future<bool> deleteAccount({String? password, String? confirmation}) async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.deleteAccount(
        password: password,
        confirmation: confirmation,
      );
      // If successful, log out immediately.
      await logout();
      return true;
    } on DioException catch (e) {
      final message = _authDioError(e, 'Account deletion failed');
      state = state.copyWith(error: message);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Account deletion failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _ref
        .read(notificationSchedulerProvider)
        .cancelAllLocalNotifications();
    final tokenStorage = _ref.read(tokenStorageProvider);
    await tokenStorage.deleteToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _googlePlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message ?? '';
    if (code.contains('sign_in_failed') ||
        message.toLowerCase().contains('10:')) {
      return 'Google sign-in could not start. Check the Android package name, SHA-1/SHA-256 fingerprints, and Web OAuth client ID.';
    }
    if (code.contains('network')) {
      return 'Google sign-in could not reach Google. Check your connection and try again.';
    }
    return 'Google sign-in failed: ${error.message ?? error.code}';
  }

  String _authDioError(DioException error, String fallback) {
    if (error.response == null &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.connectionError)) {
      return 'Could not reach the backend at ${ApiClient.baseUrl}. On a real Android device, use your computer LAN IP with API_BASE_URL.';
    }
    return friendlyAuthError(error, fallback);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
