import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';

import '../result/failures.dart';
import '../result/result.dart';
import 'exceptions/network_exceptions.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Logs an error message in debug builds only.
///
/// We never log the full response/result here — those routinely contain PII or
/// tokens. Even short exception/server messages can contain credentials;
/// callers pass only exception type metadata, and only outside release mode.
void _logError(String message) {
  if (!kReleaseMode) _logger.e(message);
}

typedef RemoteCall<T> = FutureResult<T> Function();

FutureResult<R?> safeRemoteCall<T, R>({
  required RemoteCall<T> remoteCall,
  R Function(T)? onSuccess,
  void Function(T)? onBeforeSuccess,
  String fallbackErrorMessage = 'Terjadi kesalahan tak terduga',
}) async {
  try {
    final result = await remoteCall();

    if (result.isSuccess) {
      final data = result.data;
      onBeforeSuccess?.call(data as T);
      if (onSuccess != null) return Success(onSuccess(data as T));
      return const Success(null);
    } else {
      return ResultError(
          result.failure ?? GenericFailure(message: fallbackErrorMessage));
    }
  } on NetworkException catch (e) {
    // NetworkException is a Failure — return it directly, preserving its
    // specific type (Unauthorized/NotFound/...) instead of flattening it.
    _logError('NetworkException (${e.runtimeType})');
    return ResultError(e);
  } on DioException catch (e) {
    final networkException = NetworkException.fromDioException(e);
    _logError('DioException (${networkException.runtimeType})');
    return ResultError(networkException);
  } catch (e) {
    _logError('Unexpected error (${e.runtimeType})');
    return ResultError(GenericFailure(message: e.toString()));
  }
}

FutureResult<void> safeRemoteCallVoid<T>({
  required RemoteCall<T> remoteCall,
  void Function(T)? onBeforeSuccess,
  String fallbackErrorMessage = 'Terjadi kesalahan tak terduga',
}) async {
  final result = await safeRemoteCall<T, void>(
    remoteCall: remoteCall,
    onSuccess: null,
    onBeforeSuccess: onBeforeSuccess,
    fallbackErrorMessage: fallbackErrorMessage,
  );
  return result;
}
