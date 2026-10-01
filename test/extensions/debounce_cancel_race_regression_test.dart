import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final cleanupFails in [false, true]) {
    test('SUP-04 immediate relisten is terminal; cleanup failure=$cleanupFails',
        () {
      fakeAsync((clock) {
        final zoneErrors = <Object>[];
        final cleanupError = StateError('synthetic cleanup error');

        var sourceListens = 0;
        var sourceCancels = 0;
        var secondDone = false;
        var doneBeforeCleanup = false;
        final received = <int>[];
        runZonedGuarded(() {
          final release = Completer<void>();
          final source = StreamController<int>(
              sync: true,
              onListen: () => sourceListens++,
              onCancel: () {
                sourceCancels++;
                return release.future;
              });
          final output = source.stream.debounce(const Duration(seconds: 1));
          final first = output.listen(received.add);
          source.add(1);
          first.cancel();
          output.listen(received.add, onDone: () => secondDone = true);
          clock.flushMicrotasks();
          doneBeforeCleanup = secondDone;
          if (cleanupFails) {
            release.completeError(cleanupError);
          } else {
            release.complete();
          }
          clock.flushMicrotasks();
          clock.elapse(const Duration(seconds: 2));
          expect(source.hasListener, isFalse);
        }, (e, s) => zoneErrors.add(e));
        clock.flushMicrotasks();
        expect(sourceListens, 1);
        expect(sourceCancels, 1);
        expect(received, isEmpty);
        expect(secondDone, isTrue);
        expect(zoneErrors, cleanupFails ? [same(cleanupError)] : isEmpty);
        expect(doneBeforeCleanup, isTrue,
            reason: 'done must not wait for upstream cancellation');
        expect(clock.nonPeriodicTimerCount, 0);
      });
    });
  }
}
