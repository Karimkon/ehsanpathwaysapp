import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:ehsan_pathways/config/app_config.dart';
import 'package:ehsan_pathways/core/services/notification_service.dart';

/// Handles Firebase Cloud Messaging: token registration, message handling.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _storage = const FlutterSecureStorage();

  // ─────────────────────────────────────────────────────────────────────────
  // Initialize FCM
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get and save token (iOS requires APNs token before FCM token)
    try {
      if (Platform.isIOS) {
        await _messaging.getAPNSToken().timeout(const Duration(seconds: 5));
      }
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveAndSyncToken(token);
      }
    } catch (_) {
      // APNs unavailable on simulator — non-critical, will retry on real device
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveAndSyncToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle terminated state launch
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Token management
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveAndSyncToken(String token) async {
    await _storage.write(key: 'fcm_token', value: token);
    await _syncTokenWithBackend(token);
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final authToken = await _storage.read(key: AppConfig.tokenKey);
      if (authToken == null) return; // Not logged in yet; will sync on login

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ));

      await dio.post('/device-tokens', data: {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': AppConfig.appVersion,
      });
    } catch (_) {
      // Non-critical; retry on next launch
    }
  }

  /// Call this after login to sync the FCM token with the backend.
  Future<void> syncTokenAfterLogin(String authToken) async {
    final fcmToken = await _storage.read(key: 'fcm_token');
    if (fcmToken == null) return;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ));
      await dio.post('/device-tokens', data: {
        'token': fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': AppConfig.appVersion,
      });
    } catch (_) {}
  }

  /// Call this on logout to remove the token from the backend.
  Future<void> removeTokenOnLogout(String authToken) async {
    final fcmToken = await _storage.read(key: 'fcm_token');
    if (fcmToken == null) return;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      ));
      await dio.delete('/device-tokens', data: {'token': fcmToken});
    } catch (_) {}
    await _storage.delete(key: 'fcm_token');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Message handling
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await NotificationService.instance.showImmediate(
      title: notification.title ?? 'Ehsan Pathways',
      body: notification.body ?? '',
      payload: message.data['route'] as String?,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null) {
      // Navigation will be handled by the router listener
      _pendingRoute = route;
    }
  }

  // Store a pending route from a notification tap
  String? _pendingRoute;
  String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }
}

/// Background message handler — MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart before this runs
  // For background handling, flutter_local_notifications handles the display
}
