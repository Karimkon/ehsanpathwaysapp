import 'package:flutter/material.dart';

/// One motion language for the whole app.
///
/// Animation scattered per screen reads as noise: three cards that each dip
/// by a different amount, or fade over a different duration, feel like three
/// apps. Everything that moves should move the same way, so the motion
/// becomes a grammar the user stops noticing and starts relying on.
///
/// Every widget here honours the platform's "reduce motion" setting. That
/// setting is an accessibility request from someone who may get motion
/// sickness from parallax and slides; it is not a preference to style over.
class Motion {
  const Motion._();

  /// A press, a tap ripple, a colour change.
  static const fast = Duration(milliseconds: 140);

  /// A card appearing, a sheet settling, a list item arriving.
  static const medium = Duration(milliseconds: 420);

  /// A full-screen transition.
  static const slow = Duration(milliseconds: 520);

  /// Decelerating: fast at the start, settling at the end. Things that
  /// arrive should look like they are coming to rest, not braking.
  static const enter = Curves.easeOutCubic;

  /// Symmetrical, for something that moves and returns -- a press.
  static const press = Curves.easeOut;

  /// How far a revealing element travels. Small on purpose: a long slide is
  /// the difference between "polished" and "slow".
  static const revealOffset = 14.0;

  /// Gap between consecutive items in a staggered group.
  static const stagger = Duration(milliseconds: 55);

  /// After this many items the stagger stops growing, or the last card on a
  /// long page would wait a second and a half to appear.
  static const maxStaggerSteps = 6;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Makes a card respond to touch.
///
/// A bare [GestureDetector] gives no feedback at all, and an [InkWell]'s
/// ripple is invisible over a card that paints its own gradient or image --
/// which is most of the cards in this app. So the whole card dips a little
/// under the finger and springs back.
///
/// Use this for anything card-shaped and tappable. Buttons and list rows
/// keep their Material ripple; this is for surfaces that have their own.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    this.scale = 0.975,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  /// How far it dips. Larger cards need less: the same scale moves a lot
  /// more pixels on a full-width hero than on a chip.
  final double scale;

  final String? semanticLabel;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) {
      setState(() => _down = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = Motion.reduced(context) || !_down ? 1.0 : widget.scale;

    return Padding(
      padding: widget.padding,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: target,
            duration: Motion.fast,
            curve: Motion.press,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child into place the first time it is built.
///
/// Inside a lazily-built list this doubles as a scroll reveal: an item is
/// built as it comes into view, so it arrives rather than appearing. That is
/// why the list it lives in should be a SliverList and not a column of
/// SliverToBoxAdapters -- those all build at once, off-screen, and the
/// reveal is over before anybody scrolls to it.
///
/// [index] staggers a group. Pass a running position; the delay is capped so
/// a long page does not end with a card that waits a second and a half.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = Motion.revealOffset,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  /// The stagger is part of the curve, not a timer.
  ///
  /// The first version delayed `forward()` with a Future. That left the
  /// widget sitting at opacity zero until the timer fired, so anything that
  /// interrupted the timer -- or simply did not pump a frame after it --
  /// showed the user an invisible card. It also leaves a pending timer
  /// behind, which fails a widget test at teardown.
  ///
  /// The controller runs from the first frame instead, over a window long
  /// enough to hold the delay, and an Interval keeps the child still for
  /// the first part of it. One animation, nothing pending, and it cannot
  /// end anywhere but fully visible.
  late final int _steps = widget.index.clamp(0, Motion.maxStaggerSteps);

  late final Duration _delay = Motion.stagger * _steps;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium + _delay,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMicroseconds / (Motion.medium + _delay).inMicroseconds,
      1,
      curve: Motion.enter,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;
    _started = true;

    if (Motion.reduced(context)) {
      _controller.value = 1;
      return;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        return Opacity(
          opacity: _t.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _t.value) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
