import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Caps and centres content on wide screens.
///
/// On a phone this is a no-op. On the web portal it keeps lines of translation
/// at a readable measure instead of letting them run the full width of a
/// desktop monitor, which is where long-form text becomes hard to track.
class ReadingWidth extends StatelessWidget {
  const ReadingWidth({super.key, required this.child, this.maxWidth = 820});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// The same idea expressed as padding, for scrollables whose own padding is
/// the easiest place to apply it. Returns the given insets on a phone, and
/// widens the horizontal ones on a large screen so the column stays centred
/// and readable.
EdgeInsets readingInsets(
  BuildContext context, {
  required double horizontal,
  double top = 0,
  double bottom = 0,
  double maxWidth = 820,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final gutter = math.max(horizontal, (width - maxWidth) / 2);

  return EdgeInsets.fromLTRB(gutter, top, gutter, bottom);
}
