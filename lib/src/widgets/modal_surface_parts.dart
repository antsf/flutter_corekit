// One scrolling column: title, description, bounded child, right-aligned
// actions and footer. Not exported by `widgets.dart` — package internals.

import 'package:flutter/material.dart';
import 'package:flutter_corekit/src/extensions/extensions.dart';

import 'core_icon_button.dart';

/// The scrolling body column used by both the dialog and the sheet surface.
class ModalSurfaceBody extends StatelessWidget {
  const ModalSurfaceBody({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.actions = const [],
    this.footer,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final String? description;
  final List<Widget> actions;
  final Widget? footer;

  /// Wraps ordinary body content in the frame's scrolling content.
  /// Set false for an already scrollable child (e.g. SingleChildScrollView or
  /// ListView): its height is bounded to the available content viewport while
  /// the surrounding title/actions/footer can still scroll independently.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(title!, style: context.titleLarge),
              ),
              0.75.spacingHeight,
            ],
            if (description != null) ...[
              Text(description!, style: context.bodyMedium),
              1.spacingHeight,
            ],
            if (scrollable)
              child
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: child,
              ),
            if (actions.isNotEmpty) ...[
              1.spacingHeight,
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
            if (footer != null) ...[
              1.spacingHeight,
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The >=48px close [IconButton] used by both dialog and sheet headers.
class ModalSurfaceCloseButton extends StatelessWidget {
  const ModalSurfaceCloseButton({
    super.key,
    required this.isDismissible,
    this.closeLabel,
    this.onClose,
  });

  /// False disables the button entirely.
  final bool isDismissible;
  final String? closeLabel;

  /// Overrides the button's default [Navigator.maybePop].
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    // Hard 48px floor mirrors the previous IconButton.constraints so the
    // control keeps its touch target even in a squeezed landscape header
    // (style-level minimumSize alone shrinks under parent constraints).
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: CoreIconButton(
        tooltip:
            closeLabel ?? MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: !isDismissible
            ? null
            : onClose ?? () => Navigator.of(context).maybePop(),
        // M3's IconButton theme default; kept explicit to match the reference
        // sheet close glyph regardless of the host IconButtonTheme.
        style:
            IconButton.styleFrom(foregroundColor: context.outlineVariantColor),
        icon: const Icon(Icons.close, size: 24),
      ),
    );
  }
}

// Material 3 bottom sheet drag handle: a 32×4dp fully-rounded bar in
// onSurfaceVariant (40% opacity) with 16dp padding above/below, so the whole
// affordance occupies 36dp instead of the 56dp of the stock M3 handle. The
// bar is decorative — the sheet's drag gesture is owned by the modal route,
// so it needs no 48dp touch target of its own. Ref: m3.material.io
// bottom-sheets spec and Flutter's own Material 3 default
// (widgets/bottom_sheet.dart _BottomSheetDragHandle).
const double kSheetHandleWidth = 32;
const double kSheetHandleHeight = 4;
const double kSheetHandlePadding = 16;

/// The drag handle bar itself, without the padding around it. [CoreBottomSheet]
/// wraps it in [kSheetHandlePadding] on both sides.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kSheetHandleWidth,
      height: kSheetHandleHeight,
      decoration: BoxDecoration(
        color: context.onSurfaceVariantColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(kSheetHandleHeight / 2),
      ),
    );
  }
}
