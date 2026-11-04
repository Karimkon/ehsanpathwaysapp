import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/names/asma_ul_husna_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final dark in [false, true]) {
    testWidgets('emerald header titles render white (${dark ? 'dark' : 'light'})', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const AsmaUlHusnaScreen(),
        ),
      ));
      await tester.pump();
      final title = tester.widget<RichText>(
        find.descendant(of: find.text("Asma'ul Husna"), matching: find.byType(RichText)),
      );
      expect(title.text.style?.color, Colors.white);
    });
  }
}
