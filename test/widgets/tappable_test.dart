import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tappable', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          Tappable(
            onTap: () => tapped = true,
            child: const Text('tap me'),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        wrap(
          Tappable(
            onLongPress: () => longPressed = true,
            child: const Text('hold me'),
          ),
        ),
      );

      await tester.longPress(find.text('hold me'));
      expect(longPressed, isTrue);
    });

    testWidgets('opacity feedback dims child while pressed', (tester) async {
      await tester.pumpWidget(
        wrap(
          Tappable(
            onTap: () {},
            child: const Text('press'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('press')),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidget.opacity, 0.6);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 120));

      final releasedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(releasedOpacity.opacity, 1.0);
    });

    testWidgets('scale feedback shrinks child while pressed', (tester) async {
      await tester.pumpWidget(
        wrap(
          Tappable(
            feedback: TappableFeedback.scale,
            onTap: () {},
            child: const Text('press'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('press')),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final scaleWidget = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(scaleWidget.scale, 0.96);

      await gesture.up();
    });

    testWidgets('ripple feedback uses InkWell', (tester) async {
      await tester.pumpWidget(
        wrap(
          Material(
            child: Tappable(
              feedback: TappableFeedback.ripple,
              onTap: () {},
              child: const Text('press'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('none feedback shows no opacity/scale animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Tappable(
            feedback: TappableFeedback.none,
            onTap: () {},
            child: const Text('press'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('press')),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidget.opacity, 1.0);

      final scaleWidget = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(scaleWidget.scale, 1.0);

      await gesture.up();
    });
  });
}
