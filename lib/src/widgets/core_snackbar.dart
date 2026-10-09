import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core_notice.dart';

/// Reusable notification surface. Host owns queue, positioning and motion.
/// Its close action remains pinned while long text scrolls within a short viewport.
class CoreSnackbar extends StatelessWidget {
  const CoreSnackbar(
      {super.key,
      required this.title,
      this.description,
      this.tone = CoreNoticeTone.regular,
      this.icon,
      this.isLoading = false,
      this.onTap,
      this.onClose,
      this.closeLabel = 'Dismiss notification',
      this.backgroundColor,
      this.foregroundColor,
      this.accentColor,
      this.surfaceKey,
      this.dismissKey,
      this.maxWidth = 560});
  final String title;
  final String? description;
  final CoreNoticeTone tone;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap, onClose;
  final String closeLabel;
  final Color? backgroundColor, foregroundColor, accentColor;
  final Key? surfaceKey, dismissKey;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final (background, foreground, accent, defaultIcon) =
        tone.palette(theme.colorScheme);
    final ink = foregroundColor ?? foreground;
    final tint = accentColor ?? accent;
    final reduced = media.disableAnimations || media.accessibleNavigation;
    final available = math.max(
        48.0,
        media.size.height -
            media.viewPadding.vertical -
            media.viewInsets.bottom);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: available),
      child: Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            key: surfaceKey,
            color: backgroundColor ?? background,
            elevation: 6,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: ExcludeSemantics(
                      child: isLoading && !reduced
                          ? SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: tint))
                          : Icon(
                              icon ??
                                  (isLoading
                                      ? Icons.hourglass_top
                                      : defaultIcon),
                              color: tint,
                              size: 24))),
              Expanded(
                  child: SingleChildScrollView(
                primary: false,
                child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: ink, fontWeight: FontWeight.w600)),
                            if (description != null) ...[
                              const SizedBox(height: 4),
                              Text(description!,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: ink)),
                            ],
                          ]),
                    )),
              )),
              if (onClose != null)
                Semantics(
                    label: Overlay.maybeOf(context) == null ? closeLabel : null,
                    child: IconButton(
                        key: dismissKey,
                        tooltip: Overlay.maybeOf(context) == null
                            ? null
                            : closeLabel,
                        onPressed: onClose,
                        constraints: const BoxConstraints.tightFor(
                            width: 48, height: 48),
                        padding: const EdgeInsets.all(12),
                        color: ink,
                        icon: const Icon(Icons.close, size: 24))),
            ]),
          )),
    );
  }
}
