import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/config/routes.dart';
import 'package:ehsan_pathways/core/providers/theme_provider.dart';
import 'package:ehsan_pathways/core/providers/onboarding_provider.dart';
import 'package:ehsan_pathways/core/providers/retry_policy.dart';
import 'package:ehsan_pathways/core/services/notification_service.dart';
import 'package:ehsan_pathways/core/services/fcm_service.dart';
import 'firebase_options.dart';

/// Longest any single startup step may delay the first frame.
const _startupStepTimeout = Duration(seconds: 8);

void main() {
  // Run everything inside a guarded zone so that ANY uncaught async error
  // during startup is logged instead of crashing the app on launch. A release
  // build that throws before runApp() otherwise black-screens and is killed by
  // the iOS watchdog — which is exactly what App Review reports as a crash.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Report Flutter framework errors instead of letting them escalate.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    // Firebase must succeed for messaging, but a failure here must not stop
    // the app from opening — the reviewer's device may have transient issues.
    try {
      // Bounded: on a bad network the platform call can hang indefinitely,
      // and launch must never wait on it.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_startupStepTimeout);
      // Register FCM background handler (only valid once Firebase is up).
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, s) {
      debugPrint('Firebase init failed: $e\n$s');
    }

    // Local notifications: timezone/channel setup. Non-fatal on failure.
    try {
      await NotificationService.instance.initialize().timeout(
        _startupStepTimeout,
      );
    } catch (e, s) {
      debugPrint('NotificationService init failed: $e\n$s');
    }

    // FCM token/permission/listeners. Non-fatal on failure.
    try {
      await FcmService.instance.initialize().timeout(_startupStepTimeout);
    } catch (e, s) {
      debugPrint('FcmService init failed: $e\n$s');
    }

    // Onboarding flag — default to showing onboarding if it can't be read.
    bool hasSeen = false;
    try {
      hasSeen = await hasSeenOnboarding().timeout(_startupStepTimeout);
    } catch (e, s) {
      debugPrint('hasSeenOnboarding failed: $e\n$s');
    }

    runApp(
      ProviderScope(
        retry: appRetryPolicy,
        overrides: [
          initialRouteProvider.overrideWithValue(hasSeen ? '/' : '/onboarding'),
        ],
        child: const EhsanPathwaysApp(),
      ),
    );
  }, (error, stack) {
    // Last line of defence — an error escaped every guard above.
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

class EhsanPathwaysApp extends ConsumerWidget {
  const EhsanPathwaysApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'Ehsan Pathways',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
