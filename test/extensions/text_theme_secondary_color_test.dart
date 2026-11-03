import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Distinct sentinels: if *Secondary ever drifts back to outline for text, the
  // expectation fails on the colour, not on an accidental equality.
  const outline = Color(0xFF112233);
  const onSurfaceVariant = Color(0xFF445566);

  Future<BuildContext> pumpThemed(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light()
              .copyWith(outline: outline, onSurfaceVariant: onSurfaceVariant),
        ),
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

  group('TextTheme *Secondary styles use the secondary-text role', () {
    testWidgets('body*Secondary resolve to onSurfaceVariant', (tester) async {
      final context = await pumpThemed(tester);
      for (final style in [
        context.bodyLargeSecondary,
        context.bodyMediumSecondary,
        context.bodySmallSecondary,
      ]) {
        expect(style?.color, onSurfaceVariant);
      }
    });

    testWidgets('label*Secondary resolve to onSurfaceVariant', (tester) async {
      final context = await pumpThemed(tester);
      for (final style in [
        context.labelLargeSecondary,
        context.labelMediumSecondary,
        context.labelSmallSecondary,
      ]) {
        expect(style?.color, onSurfaceVariant);
      }
    });
  });
}
