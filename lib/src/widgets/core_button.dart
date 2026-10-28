import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_corekit/flutter_corekit.dart';

enum CoreButtonVariant {
  primary,
  secondary,
  danger,
  tonalPrimary,
  tonalDanger,
  outlined,
  text,
}

/// Theme-owned action; loading preserves content geometry without painting it.
class CoreButton extends StatelessWidget {
  const CoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CoreButtonVariant.primary,
    this.isLoading = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.pill = false,
    this.fullWidth = false,
    this.minHeight = 50,
    this.loadingLabel = 'Memuat',
  }) : assert(minHeight >= 0);

  final String label, loadingLabel;
  final VoidCallback? onPressed;
  final CoreButtonVariant variant;
  final bool isLoading, enabled, pill, fullWidth;
  final Widget? leadingIcon, trailingIcon;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (variant) {
      CoreButtonVariant.primary => (
          context.primaryColor,
          context.onPrimaryColor
        ),
      CoreButtonVariant.secondary => (
          context.secondaryColor,
          context.onSecondaryColor
        ),
      CoreButtonVariant.danger => (context.errorColor, context.onErrorColor),
      CoreButtonVariant.tonalPrimary => (
          context.primaryContainerColor,
          context.onPrimaryContainerColor
        ),
      CoreButtonVariant.tonalDanger => (
          context.errorContainerColor,
          context.onErrorContainerColor
        ),
      CoreButtonVariant.outlined || CoreButtonVariant.text => (
          context.surfaceColor,
          context.primaryColor
        ),
    };
    final active = enabled && !isLoading && onPressed != null;
    final style = TextButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: isLoading
          ? background
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      disabledForegroundColor:
          isLoading ? foreground : context.onSurfaceVariantColor,
      minimumSize: Size(48, minHeight < 48 ? 48 : minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      textStyle: context.labelLarge,
      shape: pill
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: variant == CoreButtonVariant.outlined
          ? BorderSide(color: foreground)
          : null,
    );
    final content = Stack(alignment: Alignment.center, children: [
      _PreserveContentLayout(
        offstage: isLoading,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 8)
              ],
              Flexible(
                  child:
                      Text(label, textAlign: TextAlign.center, softWrap: true)),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon!
              ],
            ]),
      ),
      if (isLoading)
        Positioned.fill(
            child: Center(
                child: SizedBox.square(
          dimension: 16,
          child: TickerMode(
              enabled: !MediaQuery.disableAnimationsOf(context) &&
                  !MediaQuery.accessibleNavigationOf(context),
              child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: foreground,
                  value: MediaQuery.disableAnimationsOf(context) ||
                          MediaQuery.accessibleNavigationOf(context)
                      ? 0.75
                      : null)),
        ))),
    ]);
    final callback = active ? onPressed : null;
    final Widget button = switch (variant) {
      CoreButtonVariant.primary ||
      CoreButtonVariant.danger =>
        ElevatedButton(onPressed: callback, style: style, child: content),
      CoreButtonVariant.outlined ||
      CoreButtonVariant.tonalDanger =>
        OutlinedButton(onPressed: callback, style: style, child: content),
      _ => TextButton(onPressed: callback, style: style, child: content),
    };
    return Semantics(
        label: isLoading ? '$label, $loadingLabel' : label,
        button: true,
        enabled: active,
        liveRegion: isLoading,
        onTap: callback,
        child: ExcludeSemantics(
            child: fullWidth
                ? SizedBox(width: double.infinity, child: button)
                : button));
  }
}

/// Offstage hides painting and finder traversal; preserve real intrinsic layout.
class _PreserveContentLayout extends Offstage {
  const _PreserveContentLayout({required super.child, required super.offstage});
  @override
  RenderOffstage createRenderObject(BuildContext context) =>
      _ContentLayout(offstage: offstage);
}

class _ContentLayout extends RenderOffstage {
  _ContentLayout({required super.offstage});
  // Unlike ordinary Offstage, the hidden content still determines our size.
  @override
  bool get sizedByParent => false;
  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child!.getDryLayout(constraints);
  @override
  double computeMinIntrinsicWidth(double height) =>
      child!.getMinIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      child!.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) =>
      child!.getMinIntrinsicHeight(width);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      child!.getMaxIntrinsicHeight(width);
}
