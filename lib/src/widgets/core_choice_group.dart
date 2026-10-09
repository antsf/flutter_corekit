import 'package:flutter/material.dart';

enum CoreChoiceSelection { single, multiple }

enum CoreChoicePresentation { list, chips }

class CoreChoice<T> {
  const CoreChoice(
      {required this.value,
      required this.label,
      this.enabled = true,
      this.secondary});
  final T value;
  final String label;
  final bool enabled;
  final Widget? secondary;
}

/// Controlled checkbox row; the caller owns selection.
class CoreCheckboxOption extends StatelessWidget {
  const CoreCheckboxOption(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged,
      this.secondary,
      this.activeColor,
      this.contentPadding = EdgeInsets.zero});
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? secondary;
  final Color? activeColor;
  final EdgeInsetsGeometry contentPadding;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
      value: value,
      onChanged:
          onChanged == null ? null : (value) => onChanged!(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: contentPadding,
      activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      title: Text(label,
          softWrap: true, style: Theme.of(context).textTheme.bodyMedium),
      secondary: secondary);
}

/// Typed controlled selection. Does not mutate the caller's collection.
class CoreChoiceGroup<T> extends StatelessWidget {
  const CoreChoiceGroup(
      {super.key,
      required this.choices,
      required this.selectedValues,
      required this.onChanged,
      this.presentation = CoreChoicePresentation.list,
      this.selection = CoreChoiceSelection.multiple});
  final List<CoreChoice<T>> choices;
  final Set<T> selectedValues;
  final ValueChanged<Set<T>>? onChanged;
  final CoreChoiceSelection selection;
  final CoreChoicePresentation presentation;
  @override
  Widget build(BuildContext context) {
    assert(
        selection != CoreChoiceSelection.single || selectedValues.length <= 1);
    assert(
        choices.map((choice) => choice.value).toSet().length == choices.length);
    if (presentation == CoreChoicePresentation.chips) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final choice in choices) _chip(context, choice),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final choice in choices)
        if (selection == CoreChoiceSelection.multiple)
          CoreCheckboxOption(
              label: choice.label,
              value: selectedValues.contains(choice.value),
              secondary: choice.secondary,
              onChanged: !choice.enabled || onChanged == null
                  ? null
                  : (checked) {
                      final next = Set<T>.of(selectedValues);
                      checked
                          ? next.add(choice.value)
                          : next.remove(choice.value);
                      onChanged!(Set<T>.unmodifiable(next));
                    })
        else
          // Keep Flutter >=3.27 compatibility; RadioGroup was introduced later.
          RadioListTile<T>(
              value: choice.value,
              // ignore: deprecated_member_use
              groupValue: selectedValues.isEmpty ? null : selectedValues.first,
              // ignore: deprecated_member_use
              onChanged: !choice.enabled || onChanged == null
                  ? null
                  : (value) {
                      if (value != null) {
                        onChanged!(Set<T>.unmodifiable({value}));
                      }
                    },
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.standard,
              title: Text(choice.label,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium),
              secondary: choice.secondary),
    ]);
  }

  Widget _chip(BuildContext context, CoreChoice<T> choice) {
    final selected = selectedValues.contains(choice.value);
    final ValueChanged<bool>? callback = !choice.enabled || onChanged == null
        ? null
        : (checked) {
            final next = selection == CoreChoiceSelection.single
                ? <T>{}
                : Set<T>.of(selectedValues);
            checked ? next.add(choice.value) : next.remove(choice.value);
            onChanged!(Set<T>.unmodifiable(next));
          };
    final label = Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(choice.label, softWrap: true),
        if (choice.secondary != null) choice.secondary!,
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: selection == CoreChoiceSelection.single
          ? ChoiceChip(
              label: label,
              selected: selected,
              onSelected: callback,
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded)
          : FilterChip(
              label: label,
              selected: selected,
              onSelected: callback,
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded),
    );
  }
}
