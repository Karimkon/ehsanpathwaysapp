import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/app_config.dart';
import 'package:ehsan_pathways/core/services/auth_service.dart';

/// Shared Dio instance with auth interceptor.
final apiProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
    sendTimeout: const Duration(milliseconds: AppConfig.sendTimeout),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Attach auth token automatically
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final auth = AuthService();
      final token = await auth.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});
