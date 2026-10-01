import 'dart:async';
import 'dart:math' show pow, Random;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'network_logging.dart';

/// Random source for backoff jitter. A single shared instance is fine — jitter
/// only needs to de-correlate retries across requests, not be cryptographic.
final _retryRandom = Random();

/// Configuration options for retrying failed Dio HTTP requests.
class RetryOptions {
  /// Maximum number of retry attempts. Defaults to 3.
  final int maxAttempts;

  /// Base delay between retries in milliseconds. Defaults to 1000ms.
  final int baseDelayMs;

  /// Maximum delay cap when using exponential backoff. Defaults to 10000ms.
  final int maxDelayMs;

  /// Whether to use exponential backoff. Defaults to `true`.
  final bool useExponentialBackoff;

  /// Whether to add random jitter to the backoff delay. Defaults to `true`.
  ///
  /// Jitter spreads retries across clients so they don't all retry at the same
  /// instant (a "thundering herd") and hammer a recovering server in lockstep.
  final bool useJitter;

  /// HTTP status codes that trigger a retry. Defaults to transient error codes.
  final List<int> retryableStatusCodes;

  /// HTTP methods that are safe to retry automatically. Defaults to the
  /// idempotent methods only.
  ///
  /// **Why this matters:** a non-idempotent request (e.g. `POST`) that times out
  /// or returns a 5xx may have *already been processed* server-side. Blindly
  /// retrying it can duplicate the operation — a double payment, a duplicate
  /// order, a double transfer. Methods outside this set are therefore not
  /// retried unless the individual request explicitly opts in via
  /// `Options(extra: {'retry': true})` (use that only when the endpoint is
  /// idempotent or guarded by an idempotency key).
  final Set<String> retryableMethods;

  const RetryOptions({
    this.maxAttempts = 3,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 10000,
    this.useExponentialBackoff = true,
    this.useJitter = true,
    this.retryableStatusCodes = const [408, 500, 502, 503, 504],
    this.retryableMethods = const {'GET', 'HEAD', 'OPTIONS'},
  });

  /// Computes the delay (ms) before the given 1-based [attempt].
  int calculateDelay(int attempt) {
    final rawDelayMs = useExponentialBackoff
        ? baseDelayMs * pow(2, (attempt - 1).clamp(0, 30))
        : baseDelayMs;
    final cappedDelayMs =
        (rawDelayMs > maxDelayMs ? maxDelayMs : rawDelayMs).toInt();
    if (!useJitter || cappedDelayMs <= 0) return cappedDelayMs;
    // Equal jitter: keep half the delay fixed, randomize the other half.
    final halfDelayMs = cappedDelayMs ~/ 2;
    return halfDelayMs + _retryRandom.nextInt(cappedDelayMs - halfDelayMs + 1);
  }
}

/// Dio interceptor that automatically retries failed HTTP requests.
///
/// Retries on timeout/connection errors and configurable HTTP status codes,
/// with exponential backoff + jitter via [RetryOptions]. By default only
/// idempotent methods are retried (see [RetryOptions.retryableMethods]).
class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final RetryOptions options;
  final Logger? logger;
  final bool enableLogging;

  /// Optional session barrier, checked before and after retry backoff.
  final bool Function(RequestOptions)? canRetry;

  DioRetryInterceptor({
    required this.dio,
    this.options = const RetryOptions(),
    this.logger,
    this.enableLogging = true,
    this.canRetry,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['retry_attempt'] ??= 1;
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    if (!(canRetry?.call(requestOptions) ?? true)) {
      return handler.next(err);
    }
    final currentAttempt = requestOptions.extra['retry_attempt'] as int? ?? 1;

    final shouldRetry = _shouldRetry(err);

    if (currentAttempt < options.maxAttempts && shouldRetry) {
      final delayMs = options.calculateDelay(currentAttempt);

      if (enableLogging && logger != null) {
        logNetworkMetadata(
          logger,
          Level.info,
          'DioRetryInterceptor: Retrying request '
          '(attempt ${currentAttempt + 1}/${options.maxAttempts}) after ${delayMs}ms.',
        );
      }

      await Future.delayed(Duration(milliseconds: delayMs));
      if (!(canRetry?.call(requestOptions) ?? true)) {
        return handler.next(err);
      }
      requestOptions.extra['retry_attempt'] = currentAttempt + 1;

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      } catch (e) {
        return handler.next(DioException(
          requestOptions: requestOptions,
          error: e,
          message: 'Retry failed with non-Dio exception',
        ));
      }
    } else {
      if (enableLogging && logger != null && shouldRetry) {
        logNetworkMetadata(
          logger,
          Level.warning,
          'DioRetryInterceptor: Max retry attempts reached.',
        );
      }
      return handler.next(err);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  bool _shouldRetry(DioException err) {
    // Never retry a non-idempotent method unless the request explicitly opts in.
    final method = err.requestOptions.method.toUpperCase();
    final optedIn = err.requestOptions.extra['retry'] == true;
    if (!optedIn && !options.retryableMethods.contains(method)) {
      return false;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    if (err.response != null) {
      return options.retryableStatusCodes.contains(err.response!.statusCode);
    }
    return false;
  }
}
