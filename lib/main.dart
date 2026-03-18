import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/config/routes.dart';
import 'package:ehsan_pathways/core/providers/theme_provider.dart';
import 'package:ehsan_pathways/core/providers/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    final themeMode = ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
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
