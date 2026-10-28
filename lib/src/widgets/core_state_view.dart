import 'package:flutter/material.dart';

import '../extensions/extensions.dart';

/// Caller-selected UI state, with no inferred network or domain behavior.
enum CoreStateKind { loading, empty, error }

/// Reusable loading/empty/error composition. Callers supply localized copy and
/// an optional action widget (for example CoreButton) with their own callback.
class CoreStateView extends StatelessWidget {
  const CoreStateView(
      {super.key,
      required this.kind,
      required this.title,
      this.description,
      this.icon,
      this.action});
  final CoreStateKind kind;
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final defaultIcon = switch (kind) {
      CoreStateKind.loading => Icons.hourglass_top,
      CoreStateKind.empty => Icons.inbox_outlined,
      CoreStateKind.error => Icons.error_outline,
    };
    return Center(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                    child: Center(
                        child: kind == CoreStateKind.loading && !reduced
                            ? SizedBox.square(
                                dimension: 32,
                                child: CircularProgressIndicator(
                                    color: context.primaryColor))
                            : Icon(icon ?? defaultIcon,
                                size: 40,
                                color: kind == CoreStateKind.error
                                    ? context.errorColor
                                    : context.onSurfaceVariantColor))),
                1.spacingHeight,
                Text(title,
                    textAlign: TextAlign.center, style: context.titleLarge),
                if (description != null) ...[
                  0.5.spacingHeight,
                  Text(description!,
                      textAlign: TextAlign.center,
                      style: context.bodyMedium
                          ?.copyWith(color: context.onSurfaceVariantColor)),
                ],
                if (action != null) ...[1.5.spacingHeight, action!],
              ],
            )),
      ),
    ));
  }
}
