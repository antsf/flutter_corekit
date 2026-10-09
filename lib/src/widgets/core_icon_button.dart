import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Stateless icon action; the caller owns enabled and busy state.
class CoreIconButton extends StatelessWidget {
  const CoreIconButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.enabled = true,
      this.isLoading = false,
      this.showBadge = false,
      this.style,
      this.semanticsLabel,
      this.loadingLabel = 'Loading'});
  final Widget icon;
  final String tooltip, loadingLabel;
  final String? semanticsLabel;
  final VoidCallback? onPressed;
  final bool enabled, isLoading, showBadge;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !isLoading && onPressed != null;
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final effective = IconButton.styleFrom(minimumSize: const Size.square(48))
        .merge(style)
        .copyWith(
            minimumSize: WidgetStateProperty.resolveWith((states) {
              final size =
                  style?.minimumSize?.resolve(states) ?? const Size.square(48);
              return Size(math.max(48, size.width), math.max(48, size.height));
            }),
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.padded);
    final color = effective.foregroundColor?.resolve({}) ??
        Theme.of(context).colorScheme.primary;
    final hasOverlay = Overlay.maybeOf(context) != null;
    return Semantics(
        label: semanticsLabel ?? tooltip,
        button: true,
        enabled: active,
        value: isLoading ? loadingLabel : null,
        onTap: active ? onPressed : null,
        child: ExcludeSemantics(
            child: IconButton(
          tooltip: hasOverlay ? tooltip : null,
          onPressed: active ? onPressed : null,
          style: effective,
          icon: SizedBox.square(
              dimension: 24,
              child: isLoading
                  ? Center(
                      child: SizedBox.square(
                          dimension: 16,
                          child: TickerMode(
                              enabled: !reduced,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: color,
                                  value: reduced ? .75 : null))))
                  : Badge(isLabelVisible: showBadge, child: icon)),
        )));
  }
}
