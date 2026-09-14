import 'package:logger/logger.dart';

/// Shared [Logger] instance backing [logE], [logW], [logI], and [logD].
///
/// This is separate from any [Logger] passed into `DioClient` — that one is
/// scoped to network logging. This one is for general app-level logging.
final Logger _fcLogger = Logger(level: Logger.level);

/// Logs an error-level [message], with optional [error] and [stackTrace].
void logE(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) =>
    _fcLogger.e(message, time: time, error: error, stackTrace: stackTrace);

/// Logs a warning-level [message], with optional [error] and [stackTrace].
void logW(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) =>
    _fcLogger.w(message, time: time, error: error, stackTrace: stackTrace);

/// Logs an info-level [message], with optional [error] and [stackTrace].
void logI(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) =>
    _fcLogger.i(message, time: time, error: error, stackTrace: stackTrace);

/// Logs a debug-level [message], with optional [error] and [stackTrace].
void logD(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) =>
    _fcLogger.d(message, time: time, error: error, stackTrace: stackTrace);
