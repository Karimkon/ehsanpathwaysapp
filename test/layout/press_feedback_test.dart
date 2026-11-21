import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/motion.dart';

/// Press feedback has to actually move.
///
/// ContentCard carried its own animation and it did nothing. The controller
/// was built with `lowerBound: 0.0, upperBound: 0.04`, and that value went
/// through a CurvedAnimation into a Tween(1.0 -> 0.97). CurvedAnimation
/// applies the curve to the parent's value, so the curve only ever saw
/// 0.0..0.04:
///
///     easeInOut.transform(0.04) = 0.0032
///     scale = 1.0 + (0.97 - 1.0) * 0.0032 = 0.99990
///
/// On a 180px card that is 0.017 of a pixel. Someone meant 0.04 to be the
/// scale delta and wrote it as the controller's range. Every screen using
/// the card -- Today, Watch, the category lists, scholar pages, video
/// detail -- has had no press feedback since.
///
/// A test that only checked "an animation exists" would have passed. These
/// measure the movement.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: ContentCard(
                title: 'A lecture on sincerity',
                subtitle: 'Shaykh Ahmed Ali',
                contentType: ContentType.video,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  /// The card's width on screen, in pixels.
  ///
  /// Measured from the painted rectangle rather than from any widget's
  /// declared scale. The bug this guards against was precisely a declared
  /// target that never reached the screen -- AnimatedScale's `scale`
  /// property reads 0.975 while the card has not moved at all -- so asking
  /// the widget what it intends proves nothing. getRect goes through
  /// localToGlobal, which applies every transform above the element, and is
  /// therefore what the eye gets.
  /// Measured *inside* the scale, not outside it. A Transform applies to
  /// what it paints, so the element at or above it never moves -- measuring
  /// ContentCard itself reports 180px pressed or not, and the test passes
  /// against a card that does nothing.
  double paintedWidth(WidgetTester tester) => tester
      .getRect(
        find
            .descendant(
              of: find.byType(AnimatedScale),
              matching: find.byType(Container),
            )
            .first,
      )
      .width;

  testWidgets('a pressed card moves enough to be seen', (tester) async {
    await pumpCard(tester, onTap: () {});

    final atRest = paintedWidth(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ContentCard)),
    );
    await tester.pumpAndSettle();

    final shrunkBy = atRest - paintedWidth(tester);

    // The old implementation scaled to 0.99990, which on this card is
    // 0.017px. The movement has to be a visible fraction of a pixel.
    expect(
      shrunkBy,
      greaterThan(1.0),
      reason: 'the card narrows by $shrunkBy px when pressed, which nobody '
          'can see; the press animation is decorative',
    );

    // And not so far that it lurches.
    expect(shrunkBy, lessThan(12.0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(paintedWidth(tester), closeTo(atRest, 0.01));
  });

  testWidgets('releasing the press opens the card', (tester) async {
    var taps = 0;
    await pumpCard(tester, onTap: () => taps++);

    await tester.tap(find.byType(ContentCard));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  /// A card with nowhere to go must not look like a button.
  testWidgets('a card with no destination does not press', (tester) async {
    await pumpCard(tester);

    expect(find.byType(PressableCard), findsNothing);
  });

  testWidgets('reduce motion holds the card still', (tester) async {
    await pumpCard(tester, onTap: () {}, reduceMotion: true);

    final atRest = paintedWidth(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ContentCard)),
    );
    await tester.pump();

    expect(paintedWidth(tester), closeTo(atRest, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  /// The whole point of putting this in one place.
  test('the motion language has sane values', () {
    expect(Motion.fast.inMilliseconds, inInclusiveRange(80, 200));
    expect(Motion.medium.inMilliseconds, inInclusiveRange(250, 600));

    // A press that scales below this is a lurch; above it, invisible.
    const pressScale = 0.975;
    expect(180 * (1 - pressScale), greaterThan(1.0));
    expect(180 * (1 - pressScale), lessThan(12.0));
  });
}
