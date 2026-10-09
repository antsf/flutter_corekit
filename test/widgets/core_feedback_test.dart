import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_notice.dart';
import 'package:flutter_corekit/src/widgets/core_snackbar.dart';

Future<void> host(WidgetTester tester, Widget child,
    {double scale = 1, bool reduced = false}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
    data: MediaQueryData(
        size: const Size(320, 568),
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduced),
    child: Scaffold(
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: child))),
  )));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final scale in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets('notice/snackbar wrap long content at scale $scale',
        (tester) async {
      await host(
          tester,
          CoreSnackbar(
            title: 'Kode verifikasi berhasil dikirim ke alamat email Anda',
            description:
                List.filled(8, 'Periksa email dan masukkan kode verifikasi.')
                    .join(' '),
            tone: CoreNoticeTone.success,
            onClose: () {},
          ),
          scale: scale);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(CoreSnackbar)).height,
          lessThanOrEqualTo(220));
      final close = find.byType(IconButton);
      expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(48));
      for (final element in find.byType(RichText).evaluate()) {
        expect((element.renderObject! as RenderParagraph).didExceedMaxLines,
            isFalse);
      }
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -250));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('snackbar callbacks are independently owned by caller',
      (tester) async {
    var taps = 0;
    var closes = 0;
    await host(
        tester,
        CoreSnackbar(
            title: 'Notification',
            onTap: () => taps++,
            onClose: () => closes++));
    await tester.tap(find.text('Notification'));
    expect(taps, 1);
    await tester.tap(find.byType(IconButton));
    expect(closes, 1);
    expect(taps, 1);
  });
  testWidgets('loading respects reduced motion and has no close action',
      (tester) async {
    await host(tester, const CoreSnackbar(title: 'Memuat', isLoading: true),
        reduced: true);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
  });
  testWidgets('notice uses theme foreground and announces form feedback',
      (tester) async {
    await host(
        tester,
        const CoreNotice(
            title: 'Gagal',
            description: 'Coba lagi.',
            tone: CoreNoticeTone.error));
    final context = tester.element(find.byType(CoreNotice));
    final color = Theme.of(context).colorScheme.onErrorContainer;
    expect(tester.widget<Text>(find.text('Gagal')).style!.color, color);
    expect(tester.widget<Text>(find.text('Coba lagi.')).style!.color, color);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Semantics && widget.properties.liveRegion == true),
        findsOneWidget);
  });
  testWidgets(
      'root builder snackbar close works without a navigator Overlay ancestor',
      (tester) async {
    var closes = 0;
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => Stack(children: [
              child!,
              Align(
                  alignment: Alignment.topCenter,
                  child: CoreSnackbar(
                      title: 'Root notification', onClose: () => closes++)),
            ]),
        home: const Scaffold()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(IconButton));
    expect(closes, 1);
  });
}
