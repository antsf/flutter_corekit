import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const delay = Duration(seconds: 1);
  test('finite debounce flushes the last pending value before done', () async {
    expect(await Stream.fromIterable([1, 2, 3]).debounce(delay).toList(), [3]);
    expect(await Stream<int?>.value(null).debounce(delay).toList(), [null]);
    expect(await const Stream<int>.empty().debounce(delay).toList(), isEmpty);
  });

  test(
      'debounce flushes buffered data before forwarding error and retains stack',
      () {
    fakeAsync((clock) {
      final source = StreamController<int>(sync: true);
      final order = <String>[];
      final error = StateError('source failure');
      final stack = StackTrace.current;
      Object? seenError;
      StackTrace? seenStack;
      source.stream.debounce(delay).listen((v) => order.add('data:$v'),
          onError: (Object e, StackTrace s) {
            order.add('error');
            seenError = e;
            seenStack = s;
          },
          onDone: () => order.add('done'));
      source.add(1);
      source.addError(error, stack);
      clock.flushMicrotasks();
      expect(order, ['data:1', 'error']);
      expect(seenError, same(error));
      expect(seenStack, same(stack));
      source.add(2);
      clock.elapse(delay);
      source.close();
      clock.flushMicrotasks();
      expect(order, ['data:1', 'error', 'data:2', 'done']);
      expect(clock.nonPeriodicTimerCount, 0);
    });
  });

  test('last-listener cancellation discards pending event and releases source',
      () {
    fakeAsync((clock) {
      var cancelled = false;
      final source = StreamController<int>(
          sync: true,
          onCancel: () {
            cancelled = true;
          });
      final output = <int>[];
      final subscription = source.stream.debounce(delay).listen(output.add);
      source.add(1);
      subscription.cancel();
      clock.flushMicrotasks();
      clock.elapse(delay * 2);
      expect(output, isEmpty);
      expect(cancelled, isTrue);
      expect(clock.nonPeriodicTimerCount, 0);
      source.close();
    });
  });
}
