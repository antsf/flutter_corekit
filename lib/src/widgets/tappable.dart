/// A tap-feedback wrapper widget offering visual feedback styles beyond the
/// default [InkWell] ripple.
library;

import 'package:flutter/material.dart';

/// Visual feedback style applied by [Tappable] while pressed.
enum TappableFeedback {
  /// Standard Material ripple via [InkWell] (the default).
  ripple,

  /// Dims [child] to a lower opacity while pressed.
  opacity,

  /// Slightly shrinks [child] while pressed.
  scale,

  /// No visual feedback at all — only the tap is handled.
  none,
}

/// A tappable wrapper around [child] that reacts to press state with a
/// configurable [feedback] style, on top of the standard [onTap] /
/// [onLongPress] callbacks.
///
/// Fills a gap between raw [GestureDetector] (no visual feedback at all) and
/// [InkWell] (ripple only, and requires a [Material] ancestor) — useful for
/// custom cards, list rows, and non-Material-looking pressable widgets where
/// a subtle opacity or scale response reads better than a ripple.
///
/// Example:
/// ```dart
/// Tappable(
///   feedback: TappableFeedback.scale,
///   onTap: () => print('tapped'),
///   child: const Card(child: Text('Press me')),
/// )
/// ```
class Tappable extends StatefulWidget {
  /// Creates a [Tappable].
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.feedback = TappableFeedback.opacity,
    this.pressedOpacity = 0.6,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.behavior = HitTestBehavior.opaque,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user taps this widget.
  final VoidCallback? onTap;

  /// Called when the user long-presses this widget.
  final VoidCallback? onLongPress;

  /// The visual feedback style to apply while pressed.
  final TappableFeedback feedback;

  /// Opacity applied to [child] while pressed, when [feedback] is
  /// [TappableFeedback.opacity].
  final double pressedOpacity;

  /// Scale applied to [child] while pressed, when [feedback] is
  /// [TappableFeedback.scale].
  final double pressedScale;

  /// How long the press/release feedback animation takes.
  final Duration duration;

  /// How this widget behaves during hit testing. See [GestureDetector.behavior].
  final HitTestBehavior behavior;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feedback == TappableFeedback.ripple) {
      return InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.onTap == null && widget.onLongPress == null
          ? null
          : (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: widget.feedback == TappableFeedback.opacity && _pressed
            ? widget.pressedOpacity
            : 1.0,
        child: AnimatedScale(
          duration: widget.duration,
          scale: widget.feedback == TappableFeedback.scale && _pressed
              ? widget.pressedScale
              : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
