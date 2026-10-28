import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_text_field.dart';
import 'package:flutter_corekit/src/widgets/core_password_field.dart';

Widget host(Widget child, {double scale = 1, ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
              body: SingleChildScrollView(
                  child: SizedBox(width: 240, child: child)))),
    );

void main() {
  for (final scale in [1.0, 3.0]) {
    testWidgets('standard hint stays one line with ellipsis at scale $scale',
        (tester) async {
      const hint =
          'A deliberately long search hint that cannot fit in a narrow field';
      await tester
          .pumpWidget(host(const CoreTextField(hintText: hint), scale: scale));
      final field = tester.widget<TextField>(find.byType(TextField));
      final text = tester.widget<Text>(find.text(hint));
      expect(field.maxLines, 1);
      expect(field.decoration!.hintMaxLines, 1);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(
          tester
              .renderObject<RenderParagraph>(find.text(hint))
              .didExceedMaxLines,
          isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('textarea hint uses native text API without line truncation',
      (tester) async {
    const copy =
        'An essential hint that must remain readable and wrap at large text scales';
    await tester.pumpWidget(host(
        const CoreTextField(
          variant: CoreTextFieldVariant.textarea,
          hintText: copy,
        ),
        scale: 3));
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
        variant: CoreTextFieldVariant.textarea,
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
          const CoreTextField(hintText: 'Hint', helperText: copy),
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

  testWidgets('textarea forwards multiline content and optional line limit',
      (tester) async {
    await tester.pumpWidget(host(const CoreTextField(
      variant: CoreTextFieldVariant.textarea,
      initialValue: 'First line\nSecond line',
    )));
    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, isNull);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.controller!.text, 'First line\nSecond line');
    await tester.pumpWidget(host(const CoreTextField(
      variant: CoreTextFieldVariant.textarea,
      maxLines: 3,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
    )));
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 3);
    expect(field.keyboardType, TextInputType.text);
    expect(field.textInputAction, TextInputAction.done);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bounded textarea hint ellipsizes without painting past its lines',
      (tester) async {
    const hint = 'A long textarea hint with enough content to exceed two lines '
        'at a large text scale in a narrow input';
    await tester.pumpWidget(host(
        const CoreTextField(
          variant: CoreTextFieldVariant.textarea,
          maxLines: 2,
          hintText: hint,
        ),
        scale: 3));
    final field = tester.widget<TextField>(find.byType(TextField));
    final paragraph = tester.renderObject<RenderParagraph>(find.text(hint));
    expect(field.maxLines, 2);
    expect(field.decoration!.hintMaxLines, 2);
    expect(paragraph.maxLines, 2);
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('multiline ordinary fields and obscured textarea are rejected', () {
    expect(() => CoreTextField(maxLines: 2), throwsAssertionError);
    expect(
        () => CoreTextField(
              variant: CoreTextFieldVariant.textarea,
              obscureText: true,
            ),
        throwsAssertionError);
    expect(
        () => CoreTextField(
              variant: CoreTextFieldVariant.textarea,
              maxLines: 0,
            ),
        throwsAssertionError);
  });

  testWidgets('password hints stay single-line before and after reveal',
      (tester) async {
    const hint = 'An intentionally long password hint that must ellipsize';
    await tester.pumpWidget(host(const CorePasswordField(hintText: hint)));
    for (var reveal = 0; reveal < 2; reveal++) {
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLines, 1);
      expect(field.decoration!.hintMaxLines, 1);
      expect(
          tester.widget<Text>(find.text(hint)).overflow, TextOverflow.ellipsis);
      if (reveal == 0) {
        await tester.tap(find.byTooltip('Show password'));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint line policy preserves stateful theme colors',
      (tester) async {
    const hint = 'An intentionally long hint that must stay one line';
    final focus = FocusNode();
    final theme = ThemeData(
        inputDecorationTheme: InputDecorationTheme(
      hintStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.focused)
                ? Colors.blue
                : Colors.green,
            overflow: TextOverflow.visible,
          )),
    ));
    await tester.pumpWidget(host(
        CoreTextField(
          hintText: hint,
          focusNode: focus,
        ),
        theme: theme));
    expect(tester.widget<Text>(find.text(hint)).style!.color, Colors.green);
    expect(
        tester.widget<Text>(find.text(hint)).overflow, TextOverflow.ellipsis);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(hint)).style!.color, Colors.blue);
    expect(
        tester.widget<Text>(find.text(hint)).overflow, TextOverflow.ellipsis);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });

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
