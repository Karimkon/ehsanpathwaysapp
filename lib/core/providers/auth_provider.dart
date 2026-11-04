import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/models/user_model.dart';
import 'package:ehsan_pathways/core/models/user_stats_model.dart';
import 'package:ehsan_pathways/core/services/auth_service.dart';

// ---------------------------------------------------------------------------
// Service provider
// ---------------------------------------------------------------------------
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Run after build() returns: writing `state` while the provider is still
    // building throws "Tried to read the state of an uninitialized provider",
    // which silently broke auto-login on every launch.
    Future.microtask(_tryAutoLogin);
    return const AuthState(status: AuthStatus.loading);
  }

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> _tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _service.getToken();
      if (token == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _service.fetchCurrentUser();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _service.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericError,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _service.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericError,
      );
    }
  }

  Future<void> socialLogin({
    required String provider,
    required String token,
    String? name,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final result = await _service.socialLogin(
        provider: provider,
        token: token,
        name: name,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _genericError,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Deletes the account on the server, then signs out locally.
  /// Returns an error message to show, or null on success.
  Future<String?> deleteAccount() async {
    try {
      await _service.deleteAccount();
    } on DioException catch (e) {
      return _extractError(e);
    } catch (_) {
      return _genericError;
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
    return null;
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  static const _genericError = 'Something went wrong. Please try again.';

  String _extractError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'No internet connection. Please check your connection and try again.';
      default:
        break;
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    return _genericError;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ---------------------------------------------------------------------------
// User stats
// ---------------------------------------------------------------------------
final userStatsProvider = FutureProvider<UserStatsModel>((ref) async {
  final service = ref.watch(authServiceProvider);
  return service.fetchUserStats();
});
