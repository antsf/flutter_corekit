import 'package:fake_async/fake_async.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('only runs the last scheduled action within the window', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 100);
        final calls = <int>[];

        debouncer.run(() => calls.add(1));
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => calls.add(2));
        async.elapse(const Duration(milliseconds: 50));
        debouncer.run(() => calls.add(3));

        // Not fired yet — each run() reset the timer.
        expect(calls, isEmpty);

        async.elapse(const Duration(milliseconds: 100));
        expect(calls, [3]);

        debouncer.dispose();
      });
    });

    test('runs again after the debounce window elapses', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 50);
        final calls = <int>[];

        debouncer.run(() => calls.add(1));
        async.elapse(const Duration(milliseconds: 60));
        expect(calls, [1]);

        debouncer.run(() => calls.add(2));
        async.elapse(const Duration(milliseconds: 60));
        expect(calls, [1, 2]);

        debouncer.dispose();
      });
    });

    test('dispose cancels a pending action', () {
      fakeAsync((async) {
        final debouncer = Debouncer(milliseconds: 50);
        final calls = <int>[];

        debouncer.run(() => calls.add(1));
        debouncer.dispose();
        async.elapse(const Duration(milliseconds: 100));

        expect(calls, isEmpty);
      });
    });

    test('defaults to kDefaultDebounceMs when unspecified', () {
      expect(Debouncer().milliseconds, kDefaultDebounceMs);
    });
  });
}
