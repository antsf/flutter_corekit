import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_corekit/src/widgets/core_state_view.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final scale in [1.0, 1.5, 2.0, 3.0]) {
      for (final kind in CoreStateKind.values) {
        testWidgets('$kind state at $size scale=$scale is scrollable and wraps',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var calls = 0;
          await tester.pumpWidget(MaterialApp(
              home: MediaQuery(
            data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                disableAnimations: true),
            child: Scaffold(
                body: CoreStateView(
              kind: kind,
              title: 'Data belum dapat dimuat dari server',
              description: 'Periksa koneksi internet Anda lalu coba lagi.',
              action: kind == CoreStateKind.error
                  ? ElevatedButton(
                      onPressed: () => calls++, child: const Text('Coba Lagi'))
                  : null,
            )),
          )));
          await tester.pump();
          expect(tester.takeException(), isNull);
          if (kind == CoreStateKind.error) {
            await tester.ensureVisible(find.text('Coba Lagi'));
            await tester.tap(find.text('Coba Lagi'));
            expect(calls, 1);
          }
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
