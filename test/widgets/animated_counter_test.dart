import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedCounter', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('shows the initial count immediately by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          AnimatedCounter(
            count: 42,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets(
        'animates from 0 on first build when animateFirstValue is '
        'true', (tester) async {
      await tester.pumpWidget(
        wrap(
          AnimatedCounter(
            count: 10,
            animateFirstValue: true,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      // First frame should start the animation at 0, not jump to 10.
      expect(find.text('0'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('animates to a new value when count changes', (tester) async {
      var count = 5;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            Column(
              children: [
                AnimatedCounter(
                  count: count,
                  builder: (context, value) => Text('$value'),
                ),
                TextButton(
                  onPressed: () => setState(() => count = 20),
                  child: const Text('bump'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('bump'));
      await tester.pumpAndSettle();

      expect(find.text('20'), findsOneWidget);
    });
  });
}
