import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_button.dart';

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: Center(
        child: SizedBox(width: 320, child: Align(child: child)),
      ),
    ),
  ),
);

void main() {
  for (final variant in CoreButtonVariant.values) {
    for (final scale in [1.0, 1.5, 2.0, 3.0]) {
      for (final fullWidth in [false, true]) {
        testWidgets(
          '$variant scale $scale fullWidth $fullWidth preserves loading geometry',
          (tester) async {
            const label =
                'Simpan perubahan alamat pengiriman yang sangat panjang';
            var calls = 0;
            Widget button(bool loading) => host(
              CoreButton(
                label: label,
                onPressed: () => calls++,
                variant: variant,
                isLoading: loading,
                fullWidth: fullWidth,
                leadingIcon: const Icon(Icons.check),
                trailingIcon: const Icon(Icons.arrow_forward),
              ),
              scale: scale,
            );
            await tester.pumpWidget(button(false));
            final normal = tester.getSize(find.byType(CoreButton));
            expect(normal.height, greaterThanOrEqualTo(50));
            expect(normal.width, lessThanOrEqualTo(320));
            expect(tester.takeException(), isNull);
            final semantics = tester.ensureSemantics();
            await tester.pumpWidget(button(true));
            await tester.pump(const Duration(milliseconds: 250));
            expect(tester.getSize(find.byType(CoreButton)), normal);
            expect(find.text(label), findsNothing);
            expect(find.byType(Icon), findsNothing);
            final spinner = find.byType(CircularProgressIndicator);
            expect(tester.getSize(spinner), const Size(16, 16));
            expect(
              tester.widget<CircularProgressIndicator>(spinner).strokeWidth,
              1,
            );
            expect(
              tester.getCenter(spinner),
              tester.getCenter(find.byType(CoreButton)),
            );
            expect(find.bySemanticsLabel('$label, Memuat'), findsOneWidget);
            await tester.tap(find.byType(CoreButton));
            await tester.pump();
            expect(calls, 0);
            final style = tester
                .widget<ButtonStyleButton>(
                  find.byWidgetPredicate(
                    (widget) => widget is ButtonStyleButton,
                  ),
                )
                .style!;
            final background = style.backgroundColor!.resolve({
              WidgetState.disabled,
            })!;
            final foreground = tester
                .widget<CircularProgressIndicator>(spinner)
                .color!;
            final luminances = [
              background.computeLuminance(),
              foreground.computeLuminance(),
            ]..sort();
            expect(
              (luminances.last + 0.05) / (luminances.first + 0.05),
              greaterThanOrEqualTo(3),
            );
            await tester.pumpWidget(button(false));
            expect(tester.getSize(find.byType(CoreButton)), normal);
            expect(find.text(label), findsOneWidget);
            expect(tester.takeException(), isNull);
            semantics.dispose();
          },
        );
      }
    }
  }
  testWidgets(
    'short wrap-content label, pill, min touch, disabled and reduced motion',
    (tester) async {
      var calls = 0;
      Widget button(bool loading) => host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CoreButton(
            label: 'Ya',
            onPressed: () => calls++,
            enabled: false,
            isLoading: loading,
            minHeight: 12,
            pill: true,
          ),
        ),
      );
      await tester.pumpWidget(button(false));
      final size = tester.getSize(find.byType(CoreButton));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, lessThan(320));
      await tester.tap(find.byType(CoreButton));
      expect(calls, 0);
      await tester.pumpWidget(button(true));
      expect(tester.getSize(find.byType(CoreButton)), size);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNotNull,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
            )
            .style!
            .shape!
            .resolve({}),
        isA<StadiumBorder>(),
      );
    },
  );
  testWidgets(
    'default control is 50 high, rectangular, and keyboard actionable',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(CoreButton(label: 'Simpan', onPressed: () => calls++)),
      );
      expect(tester.getSize(find.byType(CoreButton)).height, 50);
      final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(button.style!.shape!.resolve({}), isA<RoundedRectangleBorder>());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 1);
    },
  );

  for (final variant in CoreButtonVariant.values) {
    testWidgets('$variant border only on outlined, even with a themed border', (
      tester,
    ) async {
      const themed = BorderSide(color: Colors.red, width: 3);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(side: themed),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(side: themed),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(side: themed),
            ),
          ),
          home: Scaffold(
            body: CoreButton(label: 'x', onPressed: () {}, variant: variant),
          ),
        ),
      );
      final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      final side = button.style!.side!.resolve({});
      if (variant == CoreButtonVariant.outlined) {
        expect(side!.style, BorderStyle.solid);
        expect(side.width, isNot(3));
      } else {
        expect(side, BorderSide.none);
      }
    });
  }

  group('color overrides', () {
    Material materialOf(WidgetTester tester) => tester.widget<Material>(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      ),
    );

    testWidgets('backgroundColor and foregroundColor replace the variant', (
      tester,
    ) async {
      const bg = Color(0xFF123456);
      const fg = Color(0xFFABCDEF);
      await tester.pumpWidget(
        host(
          CoreButton(
            label: 'Simpan',
            onPressed: () {},
            backgroundColor: bg,
            foregroundColor: fg,
          ),
        ),
      );
      expect(materialOf(tester).color, bg);
      final text = tester.widget<DefaultTextStyle>(
        find
            .descendant(
              of: find.byType(ElevatedButton),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, fg);
    });

    testWidgets('without overrides the variant colors are unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(CoreButton(label: 'Simpan', onPressed: () {})),
      );
      final ctx = tester.element(find.byType(ElevatedButton));
      expect(materialOf(tester).color, Theme.of(ctx).colorScheme.primary);
    });

    testWidgets('the outlined border follows foregroundColor', (tester) async {
      const fg = Color(0xFFD92D20);
      await tester.pumpWidget(
        host(
          CoreButton(
            label: 'Hapus',
            onPressed: () {},
            variant: CoreButtonVariant.outlined,
            foregroundColor: fg,
          ),
        ),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.style!.side!.resolve({})!.color, fg);
    });
  });
}
