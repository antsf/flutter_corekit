import 'dart:async';
import 'dart:ui' show VoidCallback;

/// Default debounce time (in milliseconds), matching the default used by
/// [Debouncer].
const kDefaultDebounceMs = 150;

/// {@template debouncer}
/// Runs a callback only after a period of inactivity, cancelling any
/// previously scheduled run every time [run] is called again.
///
/// Typical use: debounce a search-as-you-type `TextField.onChanged` handler
/// so the search only fires once the user pauses typing.
///
/// ```dart
/// final debouncer = Debouncer(milliseconds: 300);
///
/// TextField(
///   onChanged: (query) => debouncer.run(() => search(query)),
/// );
///
/// @override
/// void dispose() {
///   debouncer.dispose();
///   super.dispose();
/// }
/// ```
///
/// Ported from the pattern used in
/// https://github.com/itsezlife/flutter-instagram-offline-first-clone
/// (`packages/shared/lib/src/config/debouncer.dart`).
/// {@endtemplate}
class Debouncer {
  /// {@macro debouncer}
  Debouncer({this.milliseconds = kDefaultDebounceMs});

  /// The delay, in milliseconds, to wait for inactivity before [run] fires
  /// its callback.
  final int milliseconds;

  Timer? _timer;

  /// Schedules [action] to run after [milliseconds] of no further calls to
  /// [run]. Each call cancels any previously scheduled, not-yet-fired
  /// [action].
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancels any pending scheduled action. Call this from `dispose()` on
  /// whatever owns the [Debouncer] to avoid firing after teardown.
  void dispose() {
    _timer?.cancel();
  }
}
