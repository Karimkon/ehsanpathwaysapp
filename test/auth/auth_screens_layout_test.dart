import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/features/auth/login_screen.dart';
import 'package:ehsan_pathways/features/auth/register_screen.dart';

/// App Review tested build 1.1.0 (9) on an iPad Air 11-inch (M3). These tests
/// render the auth screens at phone and iPad sizes, in both orientations, and
/// fail on any RenderFlex overflow or other layout exception.
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

  Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
    // Let the fade-in animation finish.
    await tester.pump(const Duration(seconds: 1));
  }

  for (final entry in sizes.entries) {
    testWidgets('LoginScreen lays out on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value, const LoginScreen());
      expect(find.text('Sign In'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen lays out on ${entry.key}', (tester) async {
      await pumpAt(tester, entry.value, const RegisterScreen());
      expect(tester.takeException(), isNull);
    });
  }
}
