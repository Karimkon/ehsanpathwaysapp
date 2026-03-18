import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/config/routes.dart';
import 'package:ehsan_pathways/core/providers/theme_provider.dart';
import 'package:ehsan_pathways/core/providers/onboarding_provider.dart';
import 'package:ehsan_pathways/core/services/notification_service.dart';
import 'package:ehsan_pathways/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register FCM background handler before anything else
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize local notifications (timezone, channels, etc.)
  await NotificationService.instance.initialize();

  // Initialize FCM (token, permission, listeners)
  await FcmService.instance.initialize();

  final hasSeen = await hasSeenOnboarding();

  runApp(
    ProviderScope(
      overrides: [
        initialRouteProvider.overrideWithValue(hasSeen ? '/' : '/onboarding'),
      ],
      child: const EhsanPathwaysApp(),
    ),
  );
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
