import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import 'core_bottom_sheet.dart';
import 'core_text_field.dart';

/// A theme-driven searchable selection field presented through
/// [CoreBottomSheet] instead of a native popup menu.
///
/// The trigger is a read-only field row (label, selected value or hint,
/// chevron); tapping it opens a keyboard-safe sheet with a pinned search field
/// (and an inline clear control) above a filtered option list. Picking an
/// option pops the route with the typed value, so `onChanged` fires only for
/// actual selections — cancelling the sheet (barrier, back, drag or close)
/// never fires it. No new dependencies, no domain logic: labels default to
/// `item.toString()`, callers can supply an [itemLabelBuilder].
class CoreSearchDropdown<T> extends StatefulWidget {
  const CoreSearchDropdown({
    super.key,
    required this.items,
    required this.hintText,
    this.value,
    this.onChanged,
    this.labelText,
    this.errorText,
    this.sheetTitle,
    this.searchHint,
    this.closeLabel,
    this.noResultsText = 'No results',
    this.itemLabelBuilder,
    this.disabled = false,
  });

  final List<T> items;

  /// Read-only placeholder on the closed trigger.
  final String hintText;

  /// Currently selected item; null shows the hint.
  final T? value;

  /// Called with the picked item only when the sheet returns a selection.
  final ValueChanged<T?>? onChanged;

  final String? labelText;
  final String? errorText;

  /// Sheet header title; defaults to [labelText].
  final String? sheetTitle;
  final String? searchHint;

  /// The sheet close button's tooltip.
  final String? closeLabel;
  final String noResultsText;

  final String Function(T item)? itemLabelBuilder;
  final bool disabled;

  @override
  State<CoreSearchDropdown<T>> createState() => _CoreSearchDropdownState();
}

class _CoreSearchDropdownState<T> extends State<CoreSearchDropdown<T>> {
  late final _triggerFocus = FocusNode();

  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  String _labelOf(T item) =>
      widget.itemLabelBuilder?.call(item) ?? item.toString();

  void _open(BuildContext context) {
    if (widget.disabled) {
      return;
    }
    CoreBottomSheet.show<T>(
      context,
      title: widget.sheetTitle ?? widget.labelText ?? '',
      closeLabel: widget.closeLabel,
      // The search field stays pinned; only the option list scrolls.
      scrollable: false,
      child: _CoreSearchDropdownSheet(
        items: widget.items,
        labelOf: _labelOf,
        selected: widget.value,
        searchHint: widget.searchHint,
        noResultsText: widget.noResultsText,
        onPick: (item) => Navigator.of(context).pop(item),
      ),
    ).then((picked) {
      if (picked != null) {
        widget.onChanged?.call(picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? context.errorColor
        : _triggerFocus.hasFocus
            ? context.primaryColor
            : context.outlineColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.labelText != null) ...[
          Text(widget.labelText!,
              style: context.labelSmall, overflow: TextOverflow.visible),
          0.5.spacingHeight,
        ],
        Focus(
          focusNode: _triggerFocus,
          onFocusChange: (_) => setState(() {}),
          child: Ink(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            // 50 = 48px touch core + 1px borders (heights passed to the child
            // exclude the border) so the whole trigger still meets the 48
            // minimum even when the row is squeezed.
            height: 50,
            child: InkWell(
              onTap: widget.disabled ? null : () => _open(context),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.value == null
                            ? widget.hintText
                            : _labelOf(widget.value as T),
                        style: widget.value == null
                            ? context.bodyLargeSecondary
                            : context.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.keyboard_arrow_down,
                        size: 24, color: context.onSurfaceVariantColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          0.25.spacingHeight,
          Text(widget.errorText!,
              style: context.bodySmall?.copyWith(color: context.errorColor),
              overflow: TextOverflow.visible),
        ],
      ],
    );
  }
}

class _CoreSearchDropdownSheet<T> extends StatefulWidget {
  const _CoreSearchDropdownSheet({
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.onPick,
    this.searchHint,
    this.noResultsText = 'No results',
  });

  final List<T> items;
  final String Function(T item) labelOf;
  final T? selected;
  final void Function(T item) onPick;
  final String? searchHint;
  final String noResultsText;

  @override
  State<_CoreSearchDropdownSheet<T>> createState() =>
      _CoreSearchDropdownSheetState();
}

class _CoreSearchDropdownSheetState<T>
    extends State<_CoreSearchDropdownSheet<T>> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _matches(T item) =>
      widget.labelOf(item).toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final results = widget.items.where(_matches).toList(growable: false);
    // Search stays pinned above the options; only the option list scrolls.
    // The list is a loose `Flexible` so a short result set keeps the sheet at
    // its intrinsic height while a long one takes the available keyboard-safe
    // viewport and scrolls inside it.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoreTextField(
          controller: _searchController,
          focusNode: _searchFocus,
          hintText: widget.searchHint,
          textInputAction: TextInputAction.search,
          showClearButton: true,
          onChanged: (value) => setState(() => _query = value),
        ),
        0.5.spacingHeight,
        Flexible(
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (results.isEmpty)
                  Center(
                    child:
                        Text(widget.noResultsText, textAlign: TextAlign.center),
                  )
                else
                  for (final item in results)
                    InkWell(
                      onTap: () => widget.onPick(item),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.labelOf(item),
                                  style: context.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item == widget.selected)
                                Icon(
                                  Icons.check,
                                  size: 24,
                                  color: context.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
