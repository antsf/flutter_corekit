/// Relative-time ("2h ago", "3d ago") formatting for [DateTime].
library;

import 'package:timeago/timeago.dart' as timeago;

/// Adds relative-time formatting to [DateTime], e.g. `2 hours ago`.
///
/// Complements [IndonesianDate] (date_ext.dart), which formats *absolute*
/// dates in `id_ID` — use this instead when you want a relative "how long
/// ago" string (activity feeds, comment/message timestamps, "last seen").
/// English only; pass a custom `locale` to [timeAgo] for other languages
/// already registered with the `timeago` package, or register your own via
/// `timeago.setLocaleMessages`.
extension TimeAgoExt on DateTime {
  /// Formats this [DateTime] relative to now, e.g. `a moment ago`,
  /// `5 minutes ago`, `2 days ago`.
  ///
  /// [locale] defaults to `'en'`. [clock] lets tests pin "now" instead of
  /// using [DateTime.now] (see the `timeago` package's `clock` parameter).
  ///
  /// Example:
  /// ```dart
  /// DateTime.now().subtract(const Duration(minutes: 5)).timeAgo();
  /// // '5 minutes ago'
  /// ```
  String timeAgo({String locale = 'en', DateTime? clock}) =>
      timeago.format(this, locale: locale, clock: clock);

  /// Same as [timeAgo] but using the short form, e.g. `5m`, `2d`, `1y`.
  ///
  /// Requires the target locale to have a registered `_short` variant
  /// (`timeago` ships `en_short` and several others out of the box).
  String timeAgoShort({String locale = 'en', DateTime? clock}) =>
      timeago.format(this, locale: '${locale}_short', clock: clock);
}
