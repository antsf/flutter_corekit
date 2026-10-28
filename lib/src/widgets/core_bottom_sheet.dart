import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart' show TextThemeExtensions;
import 'package:flutter_corekit/src/extensions/color_scheme_ext.dart';

import 'modal_surface_parts.dart';

/// A theme-driven, keyboard-safe package-owned BottomSheet surface.
///
/// A drag handle pill sits above an optional one-row title/close header.
/// Actions and footer scroll with the body so they remain reachable in
/// landscape with a keyboard.
class CoreBottomSheet extends StatelessWidget {
  const CoreBottomSheet({
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

  /// False disables user close, barrier, back and drag dismissal.
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
    bool enableDrag = true,
    Color? barrierColor,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    final media = MediaQuery.of(context);
    final reducedMotion = media.disableAnimations || media.accessibleNavigation;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      isDismissible: isDismissible,
      enableDrag: isDismissible && enableDrag,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: barrierColor,
      constraints: BoxConstraints(maxWidth: maxWidth),
      sheetAnimationStyle: reducedMotion ? AnimationStyle.noAnimation : null,
      builder: (routeContext) => PopScope(
        canPop: isDismissible,
        child: CoreBottomSheet(
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
    ).then((result) {
      if (result == null) onClose?.call();
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: SafeArea(
          top: false,
          bottom: keyboard == 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Material(
                color: context.surfaceColor,
                elevation: 6,
                shape: theme.bottomSheetTheme.shape ??
                    const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null || showClose)
                        Flexible(
                          child: Row(
                            children: [
                              Expanded(
                                child: title != null
                                    ? SingleChildScrollView(
                                        primary: false,
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            title!,
                                            style: context.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              if (showClose)
                                ModalSurfaceCloseButton(
                                  isDismissible: isDismissible,
                                  closeLabel: closeLabel,
                                  onClose: onClose,
                                ),
                            ],
                          ),
                        ),
                      Flexible(
                        flex: 2,
                        child: ModalSurfaceBody(
                          description: description,
                          actions: actions,
                          footer: footer,
                          scrollable: scrollable,
                          showHandle: true,
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
    );
  }
}
