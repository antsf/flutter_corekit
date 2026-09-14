import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpWithBrightness(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    // Pump an empty tree first so the previous MaterialApp is fully torn
    // down instead of being updated in place — otherwise a stale captured
    // BuildContext can keep resolving Theme.of(...) against the old theme.
    await tester.pumpWidget(const SizedBox.shrink());

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return capturedContext;
  }

  group('BuildContextExtension brightness helpers', () {
    testWidgets('isLight/isDark reflect the light theme', (tester) async {
      final context = await pumpWithBrightness(tester, Brightness.light);
      expect(context.brightness, Brightness.light);
      expect(context.isLight, isTrue);
      expect(context.isDark, isFalse);
    });

    testWidgets('isLight/isDark reflect the dark theme', (tester) async {
      final context = await pumpWithBrightness(tester, Brightness.dark);
      expect(context.brightness, Brightness.dark);
      expect(context.isLight, isFalse);
      expect(context.isDark, isTrue);
    });

    testWidgets('adaptiveColor is black in light mode, white in dark mode',
        (tester) async {
      final light = await pumpWithBrightness(tester, Brightness.light);
      expect(light.adaptiveColor, Colors.black);

      final dark = await pumpWithBrightness(tester, Brightness.dark);
      expect(dark.adaptiveColor, Colors.white);
    });

    testWidgets(
        'reversedAdaptiveColor is white in light mode, black in dark mode',
        (tester) async {
      final light = await pumpWithBrightness(tester, Brightness.light);
      expect(light.reversedAdaptiveColor, Colors.white);

      final dark = await pumpWithBrightness(tester, Brightness.dark);
      expect(dark.reversedAdaptiveColor, Colors.black);
    });
  });
}
