import 'package:flutter/material.dart';
import 'package:flutter_corekit/src/widgets/core_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openModal(
  WidgetTester tester, {
  Size size = const Size(320, 568),
  double scale = 1,
  double keyboard = 0,
  bool reduced = false,
  bool accessible = false,
  bool dismissible = true,
  bool scrollable = true,
  bool showClose = true,
  VoidCallback? onClose,
  ValueChanged<Future<String?>>? onResult,
  Widget? child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduced,
        accessibleNavigation: accessible,
      ),
      child: child!,
    ),
    home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () {
                    final result = CoreBottomSheet.show<String>(
                      context,
                      title: 'A long heading that must wrap without truncation',
                      description:
                          'A detailed explanation remains fully readable at larger text sizes.',
                      isDismissible: dismissible,
                      scrollable: scrollable,
                      showClose: showClose,
                      onClose: onClose,
                      actions: [
                        TextButton(
                            onPressed: () {},
                            child: const Text('A long secondary action label')),
                        TextButton(
                            onPressed: () {},
                            child: const Text('A long primary action label')),
                      ],
                      footer: const Text('Useful footer information'),
                      child: child ??
                          const SizedBox(height: 400, child: Text('Content')),
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Open'),
                ))),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder get surface => find
    .descendant(
      of: find.byType(CoreBottomSheet),
      matching: find.byType(Material),
    )
    .first;

void main() {
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final scale in [1.0, 1.5, 2.0, 3.0]) {
      for (final keyboard in [0.0, 120.0]) {
        testWidgets('fits $size scale $scale keyboard $keyboard',
            (tester) async {
          await openModal(tester, size: size, scale: scale, keyboard: keyboard);
          expect(tester.takeException(), isNull);
          final rect = tester.getRect(surface);
          expect(rect.width, lessThanOrEqualTo(560));
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(
              rect.bottom,
              lessThanOrEqualTo(
                  size.height - keyboard - (keyboard == 0 ? 20 : 0)));
          final close = find.byTooltip('Close');
          expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
          await tester.ensureVisible(find.text('A long primary action label'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Useful footer information'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('returns typed result without cancellation callback',
      (tester) async {
    Future<String?>? result;
    var closes = 0;
    await openModal(
      tester,
      onResult: (value) => result = value,
      onClose: () => closes++,
      child: Builder(
          builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).pop('accepted'),
                child: const Text('Accept'),
              )),
    );
    await tester.ensureVisible(find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(await result, 'accepted');
    expect(closes, 0);
  });

  for (final method in ['close', 'barrier', 'back']) {
    testWidgets('$method cancellation returns null and calls onClose once',
        (tester) async {
      Future<String?>? result;
      var closes = 0;
      await openModal(tester,
          onResult: (value) => result = value, onClose: () => closes++);
      if (method == 'close') {
        await tester.tap(find.byTooltip('Close'));
      } else if (method == 'barrier') {
        await tester.tapAt(const Offset(2, 30));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(CoreBottomSheet), findsNothing);
      expect(await result, isNull);
      expect(closes, 1);
    });
  }

  testWidgets('locked modal rejects close, barrier and back without callbacks',
      (tester) async {
    var closes = 0;
    await openModal(tester, dismissible: false, onClose: () => closes++);
    await tester.tap(find.byTooltip('Close'));
    await tester.tapAt(const Offset(2, 30));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CoreBottomSheet), findsOneWidget);
    expect(closes, 0);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(CoreBottomSheet))).pop('completed');
    await tester.pumpAndSettle();
    expect(find.byType(CoreBottomSheet), findsNothing);
    expect(closes, 0);
  });

  testWidgets('supports consumer-owned scrolling without unbounded layout',
      (tester) async {
    await openModal(
      tester,
      size: const Size(568, 320),
      scale: 3,
      keyboard: 120,
      scrollable: false,
      child: SingleChildScrollView(
          child: Column(
        children: List.generate(20, (index) => Text('Consumer row $index')),
      )),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Consumer row 19'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset is consumed once and width is constrained',
      (tester) async {
    double? inset;
    await openModal(
      tester,
      size: const Size(1000, 800),
      keyboard: 120,
      child: Builder(builder: (context) {
        inset = MediaQuery.viewInsetsOf(context).bottom;
        return const SizedBox(height: 100, child: Text('Body'));
      }),
    );
    expect(inset, 0);
    expect(tester.getRect(surface).width, 560);
    expect(tester.takeException(), isNull);
  });

  for (final accessible in [false, true]) {
    testWidgets('reduced motion removes route animation accessible=$accessible',
        (tester) async {
      await openModal(tester, reduced: !accessible, accessible: accessible);
      final route =
          ModalRoute.of(tester.element(find.byType(CoreBottomSheet)))!;
      expect(route.animation!.value, 1);
      expect((route as TransitionRoute<dynamic>).transitionDuration,
          Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
    });
  }

  testWidgets('close control can be hidden', (tester) async {
    await openModal(tester, showClose: false);
    expect(find.byTooltip('Close'), findsNothing);
  });
}
