import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/retry_policy.dart';
import 'package:ehsan_pathways/features/prayer/prayer_times_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      retry: appRetryPolicy,
      child: MaterialApp(theme: AppTheme.light, home: const PrayerTimesScreen()),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('without a saved location, offers location or a city', (tester) async {
    await pump(tester, {});
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose a city'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with a saved city, shows the schedule', (tester) async {
    await pump(tester, {
      'prayer_lat': 0.3476,
      'prayer_lng': 32.5825,
      'prayer_city': 'Kampala, Uganda',
    });
    expect(find.text('Kampala, Uganda'), findsOneWidget);
    expect(find.text('Fajr'), findsWidgets);
    expect(find.text('Dhuhr'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
