import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_screen.dart';
import 'package:ehsan_pathways/features/library/library_screen.dart';
import 'package:ehsan_pathways/features/profile/profile_screen.dart';
import 'package:ehsan_pathways/features/videos/videos_screen.dart';

/// The four tabs beside Today, at the sizes App Review uses.
///
/// Nothing in the suite rendered these screens, which is how three dead
/// cards on Today and a 47px overflow in the app bar survived until the
/// owner reported them. The test font is wider than the real one, so
/// passing here leaves headroom on a device.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  const screens = <String, Widget>{
    'Watch': VideosScreen(),
    'Quran': QuranScreen(),
    'Library': LibraryScreen(),
    'Profile': ProfileScreen(),
  };

  const sizes = <String, Size>{
    'iPhone SE': Size(320, 568),
    'Pixel 5': Size(393, 851),
    'iPhone 15 Pro Max': Size(430, 932),
  };

  for (final dark in [false, true]) {
    for (final screen in screens.entries) {
      for (final size in sizes.entries) {
        testWidgets(
          '${screen.key} lays out on ${size.key} (${dark ? 'dark' : 'light'})',
          (tester) async {
            tester.view.physicalSize = size.value;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(ProviderScope(
              child: MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                home: screen.value,
              ),
            ));

            // Settle the futures and let the entrance animations finish.
            await tester.pump();
            await tester.pump(const Duration(seconds: 2));

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
