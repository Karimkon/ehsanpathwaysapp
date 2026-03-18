import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ehsan_pathways/config/app_config.dart';
import 'package:ehsan_pathways/core/models/user_model.dart';
import 'package:ehsan_pathways/core/models/user_stats_model.dart';

/// Handles all authentication-related API calls and token persistence.
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout:
                  const Duration(milliseconds: AppConfig.connectTimeout),
              receiveTimeout:
                  const Duration(milliseconds: AppConfig.receiveTimeout),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            )),
        _storage = storage ?? const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // Token helpers
  // ---------------------------------------------------------------------------

  Future<String?> getToken() => _storage.read(key: AppConfig.tokenKey);

  Future<void> _saveToken(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  Future<void> _clearToken() => _storage.delete(key: AppConfig.tokenKey);

  Options _authHeaders(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// All auth responses wrap the payload in a "data" key:
  /// { "success": true, "data": { "user": {...}, "token": "..." } }
  Map<String, dynamic> _extractData(Response response) {
    final body = response.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  /// POST /auth/login
  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = _extractData(response);
    final token = data['token'] as String;
    await _saveToken(token);
    return (user: UserModel.fromJson(data['user'] as Map<String, dynamic>), token: token);
  }

  /// POST /auth/register
  Future<({UserModel user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    final data = _extractData(response);
    final token = data['token'] as String;
    await _saveToken(token);
    return (user: UserModel.fromJson(data['user'] as Map<String, dynamic>), token: token);
  }

  /// POST /auth/google  or  POST /auth/apple
  Future<({UserModel user, String token})> socialLogin({
    required String provider, // 'google' or 'apple'
    required String token,
    String? name,
  }) async {
    final Map<String, dynamic> body = provider == 'google'
        ? {'id_token': token}
        : {
            'identity_token': token,
            if (name != null) 'name': name,
          };

    final response = await _dio.post('/auth/$provider', data: body);
    final data = _extractData(response);
    final authToken = data['token'] as String;
    await _saveToken(authToken);
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: authToken,
    );
  }

  /// POST /auth/logout
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _dio.post('/auth/logout', options: _authHeaders(token));
      } catch (_) {
        // Swallow -- we clear locally regardless.
      }
    }
    await _clearToken();
  }

  /// GET /auth/user
  Future<UserModel> fetchCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response =
        await _dio.get('/auth/user', options: _authHeaders(token));
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// GET /user/stats
  Future<UserStatsModel> fetchUserStats() async {
    final token = await getToken();
    if (token == null) return UserStatsModel.empty;
    final response =
        await _dio.get('/user/stats', options: _authHeaders(token));
    return UserStatsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
