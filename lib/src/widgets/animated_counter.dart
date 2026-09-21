/// A widget that animates changes to a numeric value, e.g. a like/comment
/// count ticking up or down.
library;

import 'package:flutter/material.dart';

/// Animates transitions between successive values of [count] using a
/// [TweenAnimationBuilder], instead of the number jumping instantly.
///
/// Useful anywhere a displayed count changes at runtime (likes, followers,
/// cart items, unread badges) and a smooth count-up/count-down reads better
/// than a hard cut.
///
/// Example:
/// ```dart
/// AnimatedCounter(
///   count: likeCount,
///   builder: (context, value) => Text('$value likes'),
/// )
/// ```
class AnimatedCounter extends StatefulWidget {
  /// Creates an [AnimatedCounter].
  const AnimatedCounter({
    super.key,
    required this.count,
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.animateFirstValue = false,
  });

  /// The current target value. Whenever this changes, the widget animates
  /// from the previous value to this one.
  final int count;

  /// Builds the display for the current animated value (which may be an
  /// intermediate value mid-animation, not just the start/end values).
  final Widget Function(BuildContext context, int value) builder;

  /// How long a single count transition takes.
  final Duration duration;

  /// The easing curve used for the count transition.
  final Curve curve;

  /// Whether to animate from 0 on the very first build.
  ///
  /// Defaults to `false`, so the initial render shows [count] immediately
  /// (e.g. a screen opening with "1,234 likes" already visible) — set to
  /// `true` to also animate the very first appearance from zero.
  final bool animateFirstValue;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  late int _previousCount = widget.animateFirstValue ? 0 : widget.count;

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _previousCount = oldWidget.count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _previousCount.toDouble(),
        end: widget.count.toDouble(),
      ),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) =>
          widget.builder(context, value.round()),
    );
  }
}
