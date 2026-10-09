import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_password_field.dart';
import 'package:flutter_corekit/src/widgets/core_icon_button.dart';
import 'package:flutter_corekit/src/widgets/core_choice_group.dart';
import 'package:flutter_corekit/src/widgets/core_status_badge.dart';

Widget host(Widget child, {double scale = 1, bool reduced = false}) =>
    MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                disableAnimations: reduced),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: SizedBox(width: 240, child: child)))));
void main() {
  for (final selection in CoreChoiceSelection.values) {
    testWidgets(
        'chips $selection replace or retain selection without mutating caller state',
        (tester) async {
      final initial = <int>{1};
      Set<int>? changed;
      await tester.pumpWidget(host(CoreChoiceGroup<int>(
        presentation: CoreChoicePresentation.chips,
        selection: selection,
        choices: const [
          CoreChoice(value: 1, label: 'One'),
          CoreChoice(value: 2, label: 'Two')
        ],
        selectedValues: initial,
        onChanged: (value) => changed = value,
      )));
      await tester.tap(find.text('Two'));
      expect(changed, selection == CoreChoiceSelection.single ? {2} : {1, 2});
      expect(initial, {1});
      await tester.tap(find.text('One'));
      expect(changed, isEmpty);
      expect(initial, {1});
    });
  }
  testWidgets('disabled chips group exposes no selection callbacks',
      (tester) async {
    await tester.pumpWidget(host(const CoreChoiceGroup<int>(
      presentation: CoreChoicePresentation.chips,
      choices: [CoreChoice(value: 1, label: 'One')],
      selectedValues: {1},
      onChanged: null,
    )));
    expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).onSelected, isNull);
  });
  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    for (final selection in CoreChoiceSelection.values) {
      testWidgets(
          'choice chips $selection scale $scale wrap and remain controlled',
          (tester) async {
        Set<int>? changed;
        await tester.pumpWidget(host(
            CoreChoiceGroup<int>(
              presentation: CoreChoicePresentation.chips,
              selection: selection,
              choices: const [
                CoreChoice(
                    value: 1,
                    label:
                        'A long choice label that must wrap at large font sizes'),
                CoreChoice(value: 2, label: 'Disabled', enabled: false)
              ],
              selectedValues: const {},
              onChanged: (value) => changed = value,
            ),
            scale: scale));
        expect(tester.takeException(), isNull);
        final chip = selection == CoreChoiceSelection.single
            ? find.byType(ChoiceChip).first
            : find.byType(FilterChip).first;
        expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(chip).width, lessThanOrEqualTo(240));
        await tester.tap(chip);
        expect(changed, {1});
        expect(() => changed!.add(2), throwsUnsupportedError);
        final disabled = selection == CoreChoiceSelection.single
            ? tester.widget<ChoiceChip>(find.byType(ChoiceChip).last).onSelected
            : tester
                .widget<FilterChip>(find.byType(FilterChip).last)
                .onSelected;
        expect(disabled, isNull);
      });
    }
  }
  testWidgets(
      'password toggle retains controller and disables suggestions even revealed',
      (tester) async {
    final controller = TextEditingController(text: 'synthetic fixture');
    await tester.pumpWidget(host(CorePasswordField(
        controller: controller, showLabel: 'Show', hideLabel: 'Hide')));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.controller, controller);
    expect(field.autofillHints, [AutofillHints.password]);
    await tester.pumpWidget(const SizedBox());
    controller.text = 'caller owned';
    controller.dispose();
  });
  testWidgets('controlled disabled password cannot toggle', (tester) async {
    var toggles = 0;
    await tester.pumpWidget(host(CorePasswordField(
        obscureText: false, onToggleObscure: () => toggles++, enabled: false)));
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    expect(toggles, 0);
  });
  testWidgets(
      'icon loading is spinner only, disabled, stable and reduced motion',
      (tester) async {
    var calls = 0;
    Widget button(bool loading) => CoreIconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
        onPressed: () => calls++,
        isLoading: loading);
    await tester.pumpWidget(host(button(false)));
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(IconButton));
    expect(calls, 1);
    await tester.pumpWidget(host(button(true), reduced: true));
    expect(tester.getSize(find.byType(IconButton)), size);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        isNotNull);
  });
  testWidgets('icon works above navigator Overlay and has a label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        builder: (_, child) => Stack(children: [
              child!,
              CoreIconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close root',
                  onPressed: () => calls++),
            ]),
        home: const Scaffold()));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Close root'), findsWidgets);
    await tester.tap(find.byType(IconButton));
    expect(calls, 1);
    semantics.dispose();
  });
  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets('controlled choices and long badges wrap at scale $scale',
        (tester) async {
      Set<int>? changed;
      await tester.pumpWidget(host(
          Column(children: [
            CoreChoiceGroup<int>(choices: const [
              CoreChoice(
                  value: 1, label: 'An exceptionally long selection label'),
              CoreChoice(value: 2, label: 'Disabled option', enabled: false)
            ], selectedValues: const {
              1
            }, onChanged: (value) => changed = value),
            const CoreStatusBadge(
                label:
                    'An exceptionally long status description that cannot be truncated',
                icon: Icons.info_outline),
          ]),
          scale: scale));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(Checkbox).first);
      expect(changed, isEmpty);
      expect(tester.widget<Checkbox>(find.byType(Checkbox).last).onChanged,
          isNull);
      expect(
          find.text(
              'An exceptionally long status description that cannot be truncated'),
          findsOneWidget);
    });
  }
  testWidgets('single choice replaces selection and disabled option is inert',
      (tester) async {
    Set<int>? changed;
    await tester.pumpWidget(host(CoreChoiceGroup<int>(
        selection: CoreChoiceSelection.single,
        choices: const [
          CoreChoice(value: 1, label: 'One'),
          CoreChoice(value: 2, label: 'Two')
        ],
        selectedValues: const {1},
        onChanged: (value) => changed = value)));
    await tester.tap(find.text('Two'));
    expect(changed, {2});
    expect(() => changed!.add(3), throwsUnsupportedError);
  });
}
