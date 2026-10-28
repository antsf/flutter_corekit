import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import 'core_notice.dart';

/// Noninteractive theme-driven status copy; essential text wraps.
class CoreStatusBadge extends StatelessWidget {
  const CoreStatusBadge(
      {super.key,
      required this.label,
      this.tone = CoreNoticeTone.regular,
      this.icon,
      this.backgroundColor,
      this.foregroundColor,
      this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      this.borderRadius = const BorderRadius.all(Radius.circular(4))});
  final String label;
  final CoreNoticeTone tone;
  final IconData? icon;
  final Color? backgroundColor, foregroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  @override
  Widget build(BuildContext context) {
    final (background, foreground, _, _) = tone.palette(context.colorScheme);
    final ink = foregroundColor ?? foreground;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: backgroundColor ?? background, borderRadius: borderRadius),
        child: Padding(
            padding: padding,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    ExcludeSemantics(child: Icon(icon, size: 16, color: ink)),
                    0.25.spacingWidth
                  ],
                  Flexible(
                      child: Text(label,
                          softWrap: true,
                          style: context.labelMedium?.copyWith(color: ink))),
                ])));
  }
}
