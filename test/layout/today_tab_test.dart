import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/home/home_provider.dart';
import 'package:ehsan_pathways/features/home/home_screen.dart';
import 'package:ehsan_pathways/shared/widgets/motion.dart';

/// The Today tab.
///
/// Three of its cards showed content and went nowhere: Daily Hadith, Daily
/// Du'a and the ayah at the foot of the page each rendered beautifully and
/// had no gesture on them at all. The hadith one was reported by the owner,
/// which is the only reason it was found -- nothing in the suite could have
/// told us, because nothing rendered this screen.
///
/// So: every card that looks tappable must be tappable, and the page must
/// lay out at phone widths in both themes.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  /// The home screen with no content from the API.
  ///
  /// HomeData's fields all default to empty, so this renders exactly the
  /// sections that are always present -- which is where all three dead
  /// cards were. The hadith provider is left to fail on purpose: the card
  /// falls back to a bundled hadith, and that fallback path must render too.
  Widget harness({required bool dark}) {
    return ProviderScope(
      overrides: [
        homeDataProvider.overrideWith((ref) async => const HomeData()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const HomeScreen(),
      ),
    );
  }

  /// Phone widths App Review actually uses, plus a small one.
  const sizes = <String, Size>{
    'iPhone SE': Size(320, 568),
    'iPhone 8': Size(375, 667),
    'Pixel 5': Size(393, 851),
    'iPhone 15 Pro Max': Size(430, 932),
  };

  for (final dark in [false, true]) {
    for (final entry in sizes.entries) {
      testWidgets(
        'Today lays out on ${entry.key} (${dark ? 'dark' : 'light'})',
        (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(harness(dark: dark));

          // Let the futures settle and the entrance animations finish.
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));

          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('the cards that show content can be opened', (tester) async {
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(dark: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Collected as we go, not at the end.
    //
    // The list is lazy, so a card scrolled far enough above the viewport is
    // disposed: the hadith card near the top is gone by the time the ayah
    // at the bottom exists. Gathering at each step is also the proof that
    // the lazy list works -- a list of fifteen eager adapters would have
    // every label present in one pass.
    final labels = <String>{};

    void collect() {
      labels.addAll(
        tester
            .widgetList<PressableCard>(find.byType(PressableCard))
            .map((card) => card.semanticLabel)
            .whereType<String>(),
      );
    }

    collect();

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 14; i++) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 300));
      collect();
    }

    for (final expected in ['hadith', "du'a", 'Quran']) {
      expect(
        labels.any((label) => label.contains(expected)),
        isTrue,
        reason: 'no openable card mentioning "$expected"; found: $labels',
      );
    }

    expect(tester.takeException(), isNull);
  });

  group('the motion language', () {
    testWidgets('a pressable card reports the tap', (tester) async {
      var taps = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableCard(
              onTap: () => taps++,
              child: const SizedBox(width: 200, height: 120),
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(PressableCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('it dips under the finger and springs back', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressableCard(
              onTap: () {},
              child: const SizedBox(width: 200, height: 120),
            ),
          ),
        ),
      ));

      double scale() => tester
          .widget<AnimatedScale>(find.byType(AnimatedScale))
          .scale;

      expect(scale(), 1.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableCard)),
      );
      await tester.pump();
      expect(scale(), lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), 1.0);
    });

    testWidgets('a reveal ends fully visible', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Reveal(index: 3, child: Text('arrived')),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
      expect(find.text('arrived'), findsOneWidget);
    });

    /// Reduce-motion is an accessibility request, not a preference to style
    /// over: someone has told their phone that movement makes them unwell.
    testWidgets('reduce motion skips the animation entirely', (tester) async {
      await tester.pumpWidget(const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Reveal(index: 5, child: Text('immediate')),
          ),
        ),
      ));

      // One pump, no time passing: it must already be at rest.
      await tester.pump();

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('reduce motion stops a card dipping', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressableCard(
                onTap: () {},
                child: const SizedBox(width: 200, height: 120),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableCard)),
      );
      await tester.pump();

      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1.0,
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
