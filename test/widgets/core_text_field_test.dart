import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_text_field.dart';

Widget host(Widget child, {double scale = 1, ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
              body: SingleChildScrollView(
                  child: SizedBox(width: 240, child: child)))),
    );

void main() {
  testWidgets(
      'hint uses the minimum-SDK native text API without line truncation',
      (tester) async {
    const copy =
        'An essential hint that must remain readable and wrap at large text scales';
    await tester
        .pumpWidget(host(const CoreTextField(hintText: copy), scale: 3));
    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration!;
    expect(decoration.hintText, copy);
    expect(decoration.hintMaxLines, copy.length + 1);
    expect(
        tester.renderObject<RenderParagraph>(find.text(copy)).didExceedMaxLines,
        isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('preserves form, controller, focus, formatting and submission',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    final form = GlobalKey<FormState>();
    String? changed, saved, submitted;
    await tester.pumpWidget(host(Form(
        key: form,
        child: CoreTextField(
          controller: controller,
          focusNode: focus,
          labelText: 'Reference',
          validator: (value) => value!.isEmpty ? 'Required' : null,
          onChanged: (value) => changed = value,
          onSaved: (value) => saved = value,
          onFieldSubmitted: (value) => submitted = value,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ))));
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'a123');
    expect(controller.text, '123');
    expect(changed, '123');
    expect(focus.hasFocus, isTrue);
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(saved, '123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, '123');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
    expect(field.keyboardType, TextInputType.number);
    await tester.pumpWidget(const SizedBox());
    controller.text = 'still owned';
    focus.requestFocus();
    controller.dispose();
    focus.dispose();
  });

  testWidgets(
      'initial value, defaults, read only, disabled and multiline forward',
      (tester) async {
    await tester.pumpWidget(host(const CoreTextField(
        initialValue: 'Initial',
        readOnly: true,
        enabled: false,
        maxLines: null,
        enableSuggestions: false,
        autocorrect: false)));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Initial');
    expect(field.readOnly, isTrue);
    expect(field.enabled, isFalse);
    expect(field.maxLines, isNull);
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
    final decoration = field.decoration!;
    expect(
        decoration.contentPadding, const EdgeInsets.symmetric(horizontal: 16));
  });

  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets('body grows and helper/errors wrap at scale $scale',
        (tester) async {
      const copy =
          'A long explanation of this field which must wrap without losing any essential information.';
      await tester.pumpWidget(host(
          const CoreTextField(hintText: copy, helperText: copy),
          scale: scale));
      final height = tester.getSize(find.byType(InputDecorator)).height;
      expect(height, greaterThanOrEqualTo(50));
      for (final element in find.text(copy).evaluate()) {
        expect(
            (element.findRenderObject()! as RenderParagraph).didExceedMaxLines,
            isFalse);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(
          const CoreTextField(errorText: copy, minHeight: 4),
          scale: scale));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(InputDecorator)).height,
          greaterThanOrEqualTo(48));
      expect(
          tester.widget<Text>(find.text(copy)).overflow, TextOverflow.visible);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('helper style resolves reactive focus, error and disabled states',
      (tester) async {
    final focus = FocusNode();
    final form = GlobalKey<FormState>();
    final theme = ThemeData(
        inputDecorationTheme: InputDecorationTheme(
      helperStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.disabled)
              ? Colors.grey
              : states.contains(WidgetState.error)
                  ? Colors.red
                  : states.contains(WidgetState.focused)
                      ? Colors.blue
                      : Colors.green)),
    ));
    Widget field({bool enabled = true, String? helper = 'Helper'}) => host(
        Form(
            key: form,
            child: CoreTextField(
                focusNode: focus,
                helperText: helper,
                enabled: enabled,
                validator: (_) => 'Invalid')),
        theme: theme);
    await tester.pumpWidget(field());
    expect(tester.widget<Text>(find.text('Helper')).style!.color, Colors.green);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Helper')).style!.color, Colors.blue);
    form.currentState!.validate();
    await tester.pump();
    expect(tester.widget<Text>(find.text('Helper')).style!.color, Colors.red);
    await tester.pumpWidget(field(helper: null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(
        const CoreTextField(helperText: 'Helper', enabled: false),
        theme: theme));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Helper')).style!.color, Colors.grey);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });

  testWidgets('semantics retains editable behavior and optional caller label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
        host(const CoreTextField(semanticsLabel: 'Account reference')));
    expect(find.bySemanticsLabel(RegExp('Account reference')), findsWidgets);
    expect(find.byType(EditableText), findsOneWidget);
    handle.dispose();
  });
}
