import 'package:flutter/material.dart';

/// Meaning is communicated by copy and icon, never color alone.
enum CoreNoticeTone { regular, success, error, warning, info }

/// Theme-derived foreground/container pairing for generic feedback surfaces.
extension CoreNoticeTonePalette on CoreNoticeTone {
  (Color, Color, Color, IconData) palette(ColorScheme colors) => switch (this) {
        CoreNoticeTone.error => (
            colors.errorContainer,
            colors.onErrorContainer,
            colors.error,
            Icons.error_outline
          ),
        CoreNoticeTone.success => (
            colors.secondaryContainer,
            colors.onSecondaryContainer,
            colors.onSecondaryContainer,
            Icons.check_circle_outline
          ),
        CoreNoticeTone.warning => (
            colors.tertiaryContainer,
            colors.onTertiaryContainer,
            colors.onTertiaryContainer,
            Icons.warning_amber_rounded
          ),
        CoreNoticeTone.info => (
            colors.primaryContainer,
            colors.onPrimaryContainer,
            colors.onPrimaryContainer,
            Icons.info_outline
          ),
        CoreNoticeTone.regular => (
            colors.surfaceContainerHigh,
            colors.onSurface,
            colors.primary,
            Icons.info_outline
          ),
      };
}

/// Persistent inline feedback. It does not fetch, validate, time out or navigate.
class CoreNotice extends StatelessWidget {
  const CoreNotice(
      {super.key,
      required this.title,
      this.description,
      this.tone = CoreNoticeTone.regular,
      this.icon,
      this.backgroundColor,
      this.foregroundColor,
      this.accentColor,
      this.liveRegion = true});
  final String title;
  final String? description;
  final CoreNoticeTone tone;
  final IconData? icon;
  final Color? backgroundColor, foregroundColor, accentColor;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground, accent, defaultIcon) =
        tone.palette(theme.colorScheme);
    final ink = foregroundColor ?? foreground;
    return Semantics(
        liveRegion: liveRegion,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: backgroundColor ?? background,
              borderRadius: BorderRadius.circular(8)),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                      child: Icon(icon ?? defaultIcon,
                          size: 20, color: accentColor ?? accent)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: ink)),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(description!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: ink)),
                        ],
                      ])),
                ],
              )),
        ));
  }
}
