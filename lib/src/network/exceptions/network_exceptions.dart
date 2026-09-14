library;

import 'package:dio/dio.dart';

import '../../result/failures.dart';

/// Defines a hierarchy of custom exceptions related to network operations.
///
/// These exceptions provide more specific and user-friendly error information
/// compared to raw [DioException]s, and they integrate with the application's
/// [Failure] and [Result] error handling pattern.

/// A base abstract class for all custom network-related exceptions.
///
/// Implements [Exception] to be throwable.
/// Each [NetworkException] carries a user-friendly [message], an optional
/// HTTP [statusCode], the original [cause] (often a [DioException]), and
/// an optional [stackTrace].
///
/// The factory constructor `NetworkException.fromDioException` is provided to
/// conveniently convert a [DioException] into a more specific [NetworkException] subtype.
abstract class NetworkException extends Failure implements Exception {
  /// Creates a const [NetworkException].
  ///
  /// A [NetworkException] **is a** [Failure] — it is the network-specific family
  /// of the unified [Failure] error model, so it can flow directly into a
  /// [Result] without a separate conversion. [statusCode] stays optional here
  /// (it defaults to `0` on the [Failure] base when unknown) so the many
  /// subtypes can keep passing `response?.statusCode`.
  // Can't use super-parameters: `statusCode` needs a `?? 0` transform (subtypes
  // pass a nullable `int?`, but Failure.statusCode is non-null), and Dart
  // forbids mixing `super.x` params with an explicit `super(...)` call.
  // ignore: use_super_parameters
  const NetworkException({
    required String message,
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          statusCode: statusCode ?? 0,
          cause: cause,
          stackTrace: stackTrace,
        );

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(runtimeType); // e.g., "TimeoutException"
    sb.write(': $message');
    if (statusCode != 0) {
      sb.write(' (Status Code: $statusCode)');
    }
    if (cause != null && cause is DioException) {
      sb.write(' URL: ${(cause as DioException).requestOptions.uri}');
    }
    return sb.toString();
  }

  /// Creates a specific [NetworkException] subtype from a given [DioException].
  ///
  /// This factory inspects the [dioException.type] and `dioException.response.statusCode`
  /// to determine the most appropriate custom exception to return.
  /// This helps in categorizing network errors for better handling in the application.
  factory NetworkException.fromDioException(DioException dioException) {
    return _mapDioExceptionToNetworkException(dioException);
  }

  static NetworkException _mapDioExceptionToNetworkException(
      DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkTimeoutException(dioException: dioException);
      case DioExceptionType.badResponse:
        return _mapStatusCodeToException(dioException);
      case DioExceptionType.cancel:
        return CancelledException(dioException: dioException);
      case DioExceptionType.connectionError:
        return NoInternetConnectionException(dioException: dioException);
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        return UnknownNetworkException(dioException: dioException);
      // This default is intentionally kept even though the switch is
      // exhaustive against the current dio version: it protects against a
      // *future* dio release adding a new DioExceptionType value (as
      // happened with `transformTimeout`), so this package degrades to
      // UnknownNetworkException instead of a hard compile break for
      // consumers who upgrade dio ahead of this package.
      // ignore: unreachable_switch_default
      default:
        return UnknownNetworkException(dioException: dioException);
    }
  }

  static NetworkException _mapStatusCodeToException(DioException dioException) {
    final statusCode = dioException.response?.statusCode;
    final dynamic responseData = dioException.response?.data;
    String? apiMessage;

    // Check if the response data is a Map and contains a 'message' or 'error' key
    if (responseData is Map<String, dynamic>) {
      apiMessage = responseData['message'] as String? ??
          responseData['error'] as String?;
    } else if (responseData is String) {
      // Handle cases where the response body is a plain string
      apiMessage = responseData;
    }

    final defaultMessage = _getDefaultMessage(statusCode);

    // Prioritize the API message if it's available and not empty.
    final finalMessage = (apiMessage != null && apiMessage.isNotEmpty)
        ? apiMessage
        : defaultMessage;

    if (statusCode == null) {
      return ServerException(dioException: dioException);
    }

    switch (statusCode) {
      case 400:
        return ClientErrorException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 401:
        return UnauthorizedException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 403:
        return ForbiddenException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 404:
        return NotFoundException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 405:
        return MethodNotAllowedException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 408:
        return RequestTimeoutException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 409:
        return ConflictException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 429:
        return TooManyRequestsException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 500:
        return InternalServerErrorException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 501:
        return NotImplementedException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 502:
        return BadGatewayException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 503:
        return ServiceUnavailableException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      case 504:
        return GatewayTimeoutException(
          dioException: dioException,
          specificMessage: finalMessage,
        );
      default:
        return ServerException(
            dioException: dioException, specificMessage: finalMessage);
    }
  }

  static String _getDefaultMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request: The request was invalid or cannot be otherwise served.';
      case 401:
        return 'Unauthorized: Authentication credentials were missing or incorrect.';
      case 403:
        return 'Forbidden: The request is understood, but it has been refused or access is not allowed.';
      case 404:
        return 'Not Found: The requested resource could not be found.';
      case 405:
        return 'Method Not Allowed: The request was made to a resource using an HTTP request method not supported by that resource.';
      case 408:
        return 'Request Timeout: The server timed out waiting for the request.';
      case 409:
        return 'Conflict: The request could not be completed due to a conflict with the current state of the resource.';
      case 429:
        return 'Too Many Requests: The user has sent too many requests in a given amount of time.';
      case 500:
        return 'Internal Server Error: The server encountered an unexpected condition that prevented it from fulfilling the request.';
      case 501:
        return 'Not Implemented: The server does not support the functionality required to fulfill the request.';
      case 502:
        return 'Bad Gateway: The server was acting as a gateway or proxy and received an invalid response from the upstream server.';
      case 503:
        return 'Service Unavailable: The server is currently unavailable.';
      case 504:
        return 'Gateway Timeout: The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.';
      default:
        return 'A server error occurred. Please try again later.';
    }
  }
}

/// Exception thrown when a network request times out (connection, send, or receive).
///
/// Named `NetworkTimeoutException` (not `TimeoutException`) to avoid shadowing
/// `dart:async`'s [TimeoutException] when both are imported.
class NetworkTimeoutException extends NetworkException {
  /// Creates a [NetworkTimeoutException].
  NetworkTimeoutException({required DioException dioException})
      : super(
          message:
              'The network request timed out. Please check your connection and try again.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown when there is no internet connection or a connection error occurs.
class NoInternetConnectionException extends NetworkException {
  /// Creates a [NoInternetConnectionException].
  NoInternetConnectionException({required DioException dioException})
      : super(
          message:
              'No internet connection. Please check your network settings and try again.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for server-side errors (e.g., HTTP status codes 5xx).
class ServerException extends NetworkException {
  /// Creates a [ServerException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  ServerException({required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'A server error occurred. Please try again later.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for client-side errors (e.g., HTTP status codes 4xx)
/// that are not more specifically handled (like Authentication or Validation failures).
class ClientErrorException extends NetworkException {
  /// Creates a [ClientErrorException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  ClientErrorException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'There was an issue with the request (Client Error).',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for unauthorized errors (HTTP status code 401).
class UnauthorizedException extends NetworkException {
  /// Creates an [UnauthorizedException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  UnauthorizedException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Unauthorized: Authentication credentials were missing or incorrect.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for forbidden errors (HTTP status code 403).
class ForbiddenException extends NetworkException {
  /// Creates a [ForbiddenException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  ForbiddenException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Forbidden: The request is understood, but it has been refused or access is not allowed.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for not found errors (HTTP status code 404).
class NotFoundException extends NetworkException {
  /// Creates a [NotFoundException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  NotFoundException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Not Found: The requested resource could not be found.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for method not allowed errors (HTTP status code 405).
class MethodNotAllowedException extends NetworkException {
  /// Creates a [MethodNotAllowedException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  MethodNotAllowedException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Method Not Allowed: The request was made to a resource using an HTTP request method not supported by that resource.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for request timeout errors (HTTP status code 408).
class RequestTimeoutException extends NetworkException {
  /// Creates a [RequestTimeoutException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  RequestTimeoutException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Request Timeout: The server timed out waiting for the request.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for conflict errors (HTTP status code 409).
class ConflictException extends NetworkException {
  /// Creates a [ConflictException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  ConflictException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Conflict: The request could not be completed due to a conflict with the current state of the resource.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for too many requests errors (HTTP status code 429).
class TooManyRequestsException extends NetworkException {
  /// Creates a [TooManyRequestsException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  TooManyRequestsException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Too Many Requests: The user has sent too many requests in a given amount of time.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for internal server errors (HTTP status code 500).
class InternalServerErrorException extends NetworkException {
  /// Creates an [InternalServerErrorException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  InternalServerErrorException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Internal Server Error: The server encountered an unexpected condition that prevented it from fulfilling the request.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for not implemented errors (HTTP status code 501).
class NotImplementedException extends NetworkException {
  /// Creates a [NotImplementedException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  NotImplementedException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Not Implemented: The server does not support the functionality required to fulfill the request.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for bad gateway errors (HTTP status code 502).
class BadGatewayException extends NetworkException {
  /// Creates a [BadGatewayException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  BadGatewayException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Bad Gateway: The server was acting as a gateway or proxy and received an invalid response from the upstream server.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for service unavailable errors (HTTP status code 503).
class ServiceUnavailableException extends NetworkException {
  /// Creates a [ServiceUnavailableException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  ServiceUnavailableException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Service Unavailable: The server is currently unavailable.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for gateway timeout errors (HTTP status code 504).
class GatewayTimeoutException extends NetworkException {
  /// Creates a [GatewayTimeoutException].
  /// [specificMessage] can be provided if a more detailed message than the default is needed.
  GatewayTimeoutException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'Gateway Timeout: The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown when a network request is cancelled by the client.
class CancelledException extends NetworkException {
  /// Creates a [CancelledException].
  CancelledException({required DioException dioException})
      : super(
          message: 'The network request was cancelled.',
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}

/// Exception thrown for unknown or unexpected network errors that don't fit
/// into other categories.
class UnknownNetworkException extends NetworkException {
  /// Creates an [UnknownNetworkException].
  UnknownNetworkException(
      {required DioException dioException, String? specificMessage})
      : super(
          message: specificMessage ??
              'An unknown network error occurred. Please try again.',
          statusCode: dioException.response?.statusCode,
          cause: dioException,
          stackTrace: dioException.stackTrace,
        );
}
