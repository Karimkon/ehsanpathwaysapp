import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/routes.dart';
import 'package:ehsan_pathways/core/providers/retry_policy.dart';
import 'package:ehsan_pathways/main.dart';

/// Boots the real app (theme, router and shell) and walks into the tools.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
  });

  testWidgets('app boots into Islamic Tools and opens the Qur\'an index', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      retry: appRetryPolicy,
      overrides: [initialRouteProvider.overrideWithValue('/islamic-tools')],
      child: const EhsanPathwaysApp(),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Islamic Tools'), findsWidgets);
    await tester.tap(find.text("Qur'an").first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Al-Fatiha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
