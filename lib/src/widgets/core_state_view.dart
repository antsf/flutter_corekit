import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
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
                                    color: theme.colorScheme.primary))
                            : Icon(icon ?? defaultIcon,
                                size: 40,
                                color: kind == CoreStateKind.error
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant))),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            )),
      ),
    ));
  }
}
