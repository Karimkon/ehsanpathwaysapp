import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/retry_policy.dart';
import 'package:ehsan_pathways/features/islamic_tools/calendar/hijri_calendar_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hifz/hifz_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/names/asma_ul_husna_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_screen.dart';
import 'package:ehsan_pathways/features/prayer/prayer_times_screen.dart';
import 'package:ehsan_pathways/features/tasbih/tasbih_screen.dart';
import 'package:ehsan_pathways/features/guidance/guidance_screen.dart';

/// Renders the redesigned screens at the sizes App Review uses, in both
/// themes, and fails on any layout overflow or build exception. The test font
/// is wider than the real ones, so passing here leaves headroom on devices.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  const sizes = <String, Size>{
    'iPhone SE': Size(375, 667),
    'iPhone 16 Pro Max': Size(440, 956),
    'iPad Air 11" portrait': Size(820, 1180),
    'iPad Air 11" landscape': Size(1180, 820),
  };

  final screens = <String, Widget Function()>{
    'Islamic Tools': () => const IslamicToolsScreen(),
    'Quran index': () => const QuranScreen(),
    'Hifz': () => const HifzScreen(),
    'Prayer Times': () => const PrayerTimesScreen(),
    "Asma'ul Husna": () => const AsmaUlHusnaScreen(),
    'Hijri Calendar': () => const HijriCalendarScreen(),
    'Tasbih': () => const TasbihScreen(),
    'Seek Guidance': () => const GuidanceScreen(),
    'Guidance form (signed out)': () => const GuidanceFormScreen(initialTopic: 'struggles'),
  };

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      for (final dark in [false, true]) {
        testWidgets('${screen.key} on ${size.key}${dark ? ' (dark)' : ''}', (tester) async {
          SharedPreferences.setMockInitialValues({
            'prayer_lat': 21.4225,
            'prayer_lng': 39.8262,
            'prayer_city': 'Makkah, Saudi Arabia',
          });
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(ProviderScope(
            retry: appRetryPolicy,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: screen.value(),
            ),
          ));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
