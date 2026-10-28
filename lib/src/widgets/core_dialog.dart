import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import 'modal_surface_parts.dart';

/// A theme-driven, keyboard-safe package-owned Dialog surface.
///
/// Titles, actions and footer scroll with the body so large text remains
/// reachable even in landscape with a keyboard. The close target stays visible.
class CoreDialog extends StatelessWidget {
  const CoreDialog({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.actions = const [],
    this.footer,
    this.showClose = true,
    this.closeLabel,
    this.isDismissible = true,
    this.onClose,
    this.scrollable = true,
    this.maxWidth = 560,
  }) : assert(maxWidth > 0);

  final Widget child;
  final String? title;
  final String? description;
  final List<Widget> actions;
  final Widget? footer;
  final bool showClose;
  final String? closeLabel;

  /// False disables user close, barrier, back and (for sheets) drag dismissal.
  /// Explicit Navigator.pop calls from the content can still return a result.
  final bool isDismissible;

  /// In direct widget use, overrides the close button's default maybePop.
  /// In [show], called once after cancellation (a null result), not confirmation.
  final VoidCallback? onClose;

  /// Wraps ordinary body content in the frame's scrolling content.
  /// Set false for an already scrollable child (e.g. SingleChildScrollView or
  /// ListView): its height is bounded to the available content viewport while
  /// the surrounding title/actions/footer can still scroll independently.
  final bool scrollable;
  final double maxWidth;

  /// Presents the package surface and returns the caller's typed route result.
  /// Reduced-motion accessibility settings remove both route transitions.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? description,
    List<Widget> actions = const [],
    Widget? footer,
    bool showClose = true,
    String? closeLabel,
    bool isDismissible = true,
    VoidCallback? onClose,
    bool scrollable = true,
    double maxWidth = 560,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) async {
    final reducedMotion = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final result = await showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      barrierDismissible: isDismissible && barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor:
          barrierColor ?? context.dialogTheme.barrierColor ?? Colors.black54,
      transitionDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 200),
      pageBuilder: (routeContext, animation, secondaryAnimation) => themes.wrap(
        Builder(
          builder: (routeContext) => PopScope(
            canPop: isDismissible,
            child: CoreDialog(
              title: title,
              description: description,
              actions: actions,
              footer: footer,
              showClose: showClose,
              closeLabel: closeLabel,
              isDismissible: isDismissible,
              scrollable: scrollable,
              maxWidth: maxWidth,
              child: child,
            ),
          ),
        ),
      ),
    );
    if (result == null) onClose?.call();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = context.keyboardHeight;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: SafeArea(
          top: true,
          bottom: keyboard == 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Material(
                  color: context.surfaceColor,
                  elevation: 6,
                  shape: context.dialogTheme.shape ??
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showClose)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ModalSurfaceCloseButton(
                              isDismissible: isDismissible,
                              closeLabel: closeLabel,
                              onClose: onClose,
                            ),
                          ),
                        Flexible(
                          child: ModalSurfaceBody(
                            title: title,
                            description: description,
                            actions: actions,
                            footer: footer,
                            scrollable: scrollable,
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
