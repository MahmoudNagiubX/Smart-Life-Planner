import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

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
  final Ref _ref;

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
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
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
      final message = e.response?.data['detail'] ?? 'Registration failed';
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
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
      final message = e.response?.data['detail'] ?? 'Login failed';
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
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