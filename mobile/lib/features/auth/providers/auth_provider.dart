import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/network/providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

String _extractAuthError(DioException error, String fallback) {
  final data = error.response?.data;

  if (data is Map) {
    final detail = data['detail'];
    final message = data['message'];
    final errors = data['errors'];

    if (errors is List && errors.isNotEmpty) {
      final validationMessage = errors
          .map((item) {
            if (item is Map) {
              final field = item['field'];
              final itemMessage = item['message'] ?? item['msg'];
              if (field is String && itemMessage is String) {
                return '$field: $itemMessage';
              }
              if (itemMessage is String) {
                return itemMessage;
              }
            }
            return item.toString();
          })
          .join('\n');

      if (detail is String && detail.isNotEmpty) {
        return '$detail\n$validationMessage';
      }
      return validationMessage;
    }

    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    if (message is String && message.isNotEmpty) {
      return message;
    }
  }

  if (data is String && data.isNotEmpty) {
    return data;
  }

  final networkMessage = error.message ?? error.error?.toString();
  if (networkMessage != null && networkMessage.isNotEmpty) {
    return networkMessage;
  }

  return fallback;
}

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
    final hasToken = await tokenStorage.hasToken();
    if (hasToken) {
      try {
        final authService = _ref.read(authServiceProvider);
        final user = await authService.getMe();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        await tokenStorage.deleteToken();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.register(
        email: email,
        fullName: fullName,
        password: password,
      );
      await login(email: email, password: password);
    } on DioException catch (e) {
      final message = _extractAuthError(e, 'Registration failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
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
      final message = _extractAuthError(e, 'Login failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  Future<void> googleLogin() async {
    try {
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
      final message = _extractAuthError(e, 'Google sign-in failed');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Google sign-in failed: $e',
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
      final message = _extractAuthError(e, 'Apple sign-in failed');
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

  Future<void> logout() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    await tokenStorage.deleteToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
