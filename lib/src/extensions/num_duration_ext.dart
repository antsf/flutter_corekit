/// Extension on [num] for concise [Duration] construction.
///
/// Ported from the pattern used in
/// https://github.com/itsezlife/flutter-instagram-offline-first-clone
/// (`packages/shared/lib/src/config/utilities/extensions/num_duration_extension.dart`).
///
/// ```dart
/// 200.ms      // Duration(milliseconds: 200)
/// 3.seconds   // Duration(milliseconds: 3000)
/// 1.5.minutes // Duration(seconds: 90)
/// ```
extension NumDurationExt on num {
  /// This number of microseconds as a [Duration].
  Duration get microseconds => Duration(microseconds: round());

  /// This number of milliseconds as a [Duration]. Alias: [ms].
  Duration get milliseconds => (this * 1000).microseconds;

  /// Shorthand for [milliseconds].
  Duration get ms => milliseconds;

  /// This number of seconds as a [Duration].
  Duration get seconds => (this * 1000 * 1000).microseconds;

  /// This number of minutes as a [Duration].
  Duration get minutes => (this * 1000 * 1000 * 60).microseconds;

  /// This number of hours as a [Duration].
  Duration get hours => (this * 1000 * 1000 * 60 * 60).microseconds;

  /// This number of days as a [Duration].
  Duration get days => (this * 1000 * 1000 * 60 * 60 * 24).microseconds;
}
