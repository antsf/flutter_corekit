import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
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
    final reducedMotion = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
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
    final keyboard = context.keyboardHeight;
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
                shape: context.bottomSheetTheme.shape ??
                    const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, outer) {
                    // The handle is the lowest layout priority: on a
                    // comfortable sheet it always renders, but it is dropped
                    // entirely rather than letting the title/close row's
                    // guaranteed 48dp touch target (close at a 1:2
                    // header:body split of whatever remains) shrink below
                    // spec. 36 = 16dp padding above + 4dp bar + 16dp below;
                    // 144 = 48 * 3 (header's worst-case 1/3 share needs to
                    // clear 48 on its own).
                    const handleReserve =
                        kSheetHandlePadding * 2 + kSheetHandleHeight;
                    final showHandle = outer.maxHeight.isFinite &&
                        outer.maxHeight - handleReserve >= 144;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHandle)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: kSheetHandlePadding),
                            child: Center(child: SheetDragHandle()),
                          ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                                                  FontWeight
                                                                      .w600),
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
                                    child: child,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
