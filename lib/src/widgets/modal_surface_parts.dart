// One scrolling column: title, description, bounded child, right-aligned
// actions and footer. Not exported by `widgets.dart` — package internals.

import 'package:flutter/material.dart';

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
    this.showHandle = false,
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

  /// Whether to paint the sheet's drag handle pill at the top of the column
  /// (sheets only; the dialog never shows one).
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
              Center(
                child: Container(
                  width: kSheetHandleWidth,
                  height: kSheetHandleHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(kSheetHandleHeight),
                  ),
                ),
              ),
              const SizedBox(height: kSheetHandleGap),
            ],
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(title!, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
            ],
            if (description != null) ...[
              Text(description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (scrollable)
              child
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: child,
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 16),
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
        style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
        icon: const Icon(Icons.close, size: 24),
      ),
    );
  }
}

// Reference sheet handle (drag pill): app tokens map to
// avatar=40, xs=4, sm=8, pill=fully rounded ends; touchTarget/icon are already
// enforced by CoreIconButton (48) and the standard Icon size (24).
const double kSheetHandleWidth = 40;
const double kSheetHandleHeight = 4;
const double kSheetHandleGap = 8;
