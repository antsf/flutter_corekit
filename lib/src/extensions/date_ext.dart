// lib/src/date_ext.dart
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Extension methods for [DateTime] to format dates and times in Indonesian.
extension IndonesianDate on DateTime {
  static bool _initialized = false;
  static Future<void>? _initializing;

  /// Ensures Indonesian (`id_ID`) locale data is loaded before any of this
  /// extension's formatting methods are called.
  ///
  /// `initializeDateFormatting` is asynchronous the first time it loads a
  /// locale's data; calling a formatter before that completes can throw
  /// `LocaleDataException`. Call and `await` this once during app startup
  /// (e.g. in `main()`) for a reliable first render:
  ///
  /// ```dart
  /// await IndonesianDate.ensureInitialized();
  /// runApp(MyApp());
  /// ```
  ///
  /// Safe to call multiple times/concurrently — the underlying load only
  /// happens once; subsequent calls reuse the same in-flight/completed
  /// future.
  static Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    return _initializing ??= initializeDateFormatting('id_ID', null).then((_) {
      _initialized = true;
    });
  }

  /// Best-effort synchronous initialization for callers that never awaited
  /// [ensureInitialized]. Triggers the load at most once (fire-and-forget)
  /// instead of re-running `initializeDateFormatting` on every format call.
  ///
  /// If the very first formatter call happens before the locale data has
  /// finished loading, `DateFormat` may throw. Prefer awaiting
  /// [ensureInitialized] once at startup to avoid that entirely.
  static void initialize() {
    if (_initialized || _initializing != null) return;
    _initializing = initializeDateFormatting('id_ID', null).then((_) {
      _initialized = true;
    });
  }

  /// Formats the date to a short Indonesian format (e.g., `26/06/2025`).
  String toShortIndonesianDate() {
    initialize();
    return DateFormat('dd/MM/yyyy', 'id_ID').format(this);
  }

  /// Formats the date with a short month name (e.g., `26 Jun 2025`).
  String toShortMonthName() {
    initialize();
    return DateFormat('d MMM yyyy', 'id_ID').format(this);
  }

  /// Formats the date with a full month name (e.g., `26 Juni 2025`).
  String toIndonesianDate() {
    initialize();
    return DateFormat('d MMMM yyyy', 'id_ID').format(this);
  }

  /// Formats the date with the full day of the week (e.g., `Kamis, 26 Juni 2025`).
  String toIndonesianDateWithDay() {
    initialize();
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(this);
  }

  /// Formats the date with the full day of the week and time (e.g., `Kamis, 26 Juni 2025 14:30`).
  String toIndonesianDateTime() {
    initialize();
    return DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(this);
  }

  /// Formats the date with the full day of the week and time (e.g., `Kamis, 26 Jun 2025 14:30`).
  String toShortMonthNameWithDay() {
    initialize();
    return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(this);
  }

  /// Formats the date with full month name and time (e.g., `26 Juni 2025 14:30`).
  String toIndonesianDateTimeString() {
    initialize();
    return DateFormat('d MMMM yyyy HH:mm', 'id_ID').format(this);
  }

  /// Formats the date with full month name and time (e.g., `26 Juni 2025 14:30:00`).
  String toDateTimeWithSeconds() {
    initialize();
    return DateFormat('d MMMM yyyy HH:mm:ss', 'id_ID').format(this);
  }

  /// Formats the date with short month name and time (e.g., `26 Jun 2025 14:30`).
  String toShortDateTime() {
    initialize();
    return DateFormat('d MMM yyyy HH:mm', 'id_ID').format(this);
  }

  /// Formats to a short date and time (e.g., `26/06/2025 14:30`).
  String toShortDateWithTime() {
    initialize();
    return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(this);
  }

  /// Formats the time to `dd/MM` (e.g., `26/06`).
  String toDayAndMonth() {
    initialize();
    return DateFormat('dd/MM', 'id_ID').format(this);
  }

  /// Formats the time to `HH:mm` (e.g., `14:30`).
  String toTime() {
    initialize();
    return DateFormat('HH:mm', 'id_ID').format(this);
  }

  /// Formats the time to `HH:mm:ss` (e.g., `14:30:45`).
  String toTimeWithSeconds() {
    initialize();
    return DateFormat('HH:mm:ss', 'id_ID').format(this);
  }

  /// Formats the date for a database (e.g., `2025-06-26`). Locale-independent.
  String toIsoDate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// Formats the full date and time for a database (e.g., `2025-06-26 14:30:45`).
  /// Locale-independent.
  String toDbDateTimeFormat() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
  }
}
