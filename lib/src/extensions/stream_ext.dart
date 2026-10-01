import 'dart:async';

/// Stream utility extensions — debounce and throttle without external dependencies.
extension StreamExtension<T> on Stream<T> {
  /// Emits a value after [duration] of silence. Completion flushes the last
  /// pending value before done. Errors flush pending data before forwarding
  /// the same error/stack, then the stream can continue. Cancelling the last
  /// listener discards pending data, releases the source and closes this
  /// broadcast pipeline; a later listener receives done, not a new source.
  /// Upstream cancellation errors are reported once to the creating Zone;
  /// they do not reopen the pipeline or delay output completion.
  Stream<T> debounce(Duration duration) {
    final controller = StreamController<T>.broadcast();
    Timer? timer;
    StreamSubscription<T>? sub;
    late T pending;
    var hasPending = false;
    var terminal = false;
    final zone = Zone.current;
    void flush() {
      timer?.cancel();
      timer = null;
      if (hasPending && !controller.isClosed) {
        final value = pending;
        hasPending = false;
        controller.add(value);
      }
    }

    controller.onListen = () {
      if (terminal) return;
      sub = listen(
        (event) {
          pending = event;
          if (terminal) return;
          hasPending = true;
          timer?.cancel();
          timer = Timer(duration, flush);
        },
        onError: (Object e, StackTrace s) {
          flush();
          if (!controller.isClosed) controller.addError(e, s);
        },
        onDone: () {
          flush();
          terminal = true;
          controller.close();
        },
      );
    };
    controller.onCancel = () {
      if (terminal) return;
      terminal = true;
      timer?.cancel();
      timer = null;
      hasPending = false;
      final subscription = sub;
      sub = null;
      // Broadcast controllers do not await onCancel. Close before yielding so
      // immediate relisten observes a terminal pipeline, not a second source.
      unawaited(controller.close());
      if (subscription != null) {
        Future<void>.sync(subscription.cancel).then<void>((_) {},
            onError: (Object error, StackTrace stack) {
          zone.handleUncaughtError(error, stack);
        });
      }
    };
    return controller.stream;
  }

  /// Emits the first event then ignores subsequent events for [duration].
  Stream<T> throttle(Duration duration) {
    final controller = StreamController<T>.broadcast();
    bool throttled = false;
    StreamSubscription<T>? sub;
    controller.onListen = () {
      sub = listen(
        (event) {
          if (!throttled) {
            throttled = true;
            if (!controller.isClosed) controller.add(event);
            Timer(duration, () => throttled = false);
          }
        },
        onError: (Object e, StackTrace s) {
          if (!controller.isClosed) controller.addError(e, s);
        },
        onDone: () => controller.close(),
      );
    };
    controller.onCancel = () {
      final pending = sub?.cancel();
      sub = null;
      return pending;
    };
    return controller.stream;
  }
}
