import 'dart:async';

import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_corekit/src/network/dio_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class CaptureOutput extends LogOutput {
  final lines = <String>[];
  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

class AllowLogs extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class ConsumeErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {}
}

void main() {
  test(
      'active network logging omits credentials in URI, bodies, headers and errors',
      () {
    const sentinel = 'CREDENTIAL_SENTINEL_NOT_REAL';
    final output = CaptureOutput();
    final logger = Logger(
        filter: AllowLogs(),
        printer: SimplePrinter(colors: false),
        output: output);
    final logging = DioLoggingInterceptor(logger: logger);
    final options = RequestOptions(
        path: 'https://user:$sentinel@api.test/login?token=$sentinel#fragment',
        headers: {
          'Authorization': 'Bearer $sentinel',
          'X-Custom-Credential': sentinel
        },
        data: {
          'password': sentinel,
          'nested': [
            {'access_token': sentinel}
          ]
        });
    logging.onRequest(options, RequestInterceptorHandler());
    logging.onResponse(
        Response(
            requestOptions: options,
            statusCode: 200,
            statusMessage: sentinel,
            data: {'access_token': sentinel}),
        ResponseInterceptorHandler());
    logging.onError(
        DioException(
            requestOptions: options,
            message: sentinel,
            error: StateError(sentinel),
            type: DioExceptionType.badResponse,
            response: Response(
                requestOptions: options,
                statusCode: 400,
                statusMessage: sentinel,
                data: {
                  'error': {'password': sentinel}
                })),
        ConsumeErrorHandler());
    options.data = FormData.fromMap({'password': sentinel, 'otp': sentinel});
    logging.onRequest(options, RequestInterceptorHandler());
    options.data = 'password=$sentinel';
    logging.onRequest(options, RequestInterceptorHandler());
    expect(output.lines, isNotEmpty);
    expect(output.lines.join('\n'), isNot(contains(sentinel)));
    expect(options.headers['Authorization'], 'Bearer $sentinel',
        reason: 'logging must not mutate the request');
    logger.close();
  });

  test('safeRemoteCall does not log raw exception or server credential text',
      () async {
    const sentinel = 'CREDENTIAL_SENTINEL_NOT_REAL';
    final request = RequestOptions(path: '/login');
    final dioError = DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(
            requestOptions: request,
            statusCode: 400,
            data: {'message': sentinel}));
    for (final error in [
      dioError,
      NetworkException.fromDioException(dioError),
      StateError(sentinel)
    ]) {
      final printed = <String>[];
      await runZoned(() async {
        final result = await safeRemoteCall<Object, Object>(
            remoteCall: () async => throw error);
        expect(result.isFailure, isTrue);
      },
          zoneSpecification: ZoneSpecification(
              print: (_, parent, zone, line) => printed.add(line)));
      expect(printed.join('\n'), isNot(contains(sentinel)));
    }
  });

  test(
      'password and OTP diagnostics never reveal value but generic inputs remain readable',
      () {
    const sentinel = 'CREDENTIAL_SENTINEL_NOT_REAL';
    expect(const PasswordInput.dirty(sentinel).toString(),
        isNot(contains(sentinel)));
    expect(
        const OtpInput.dirty(sentinel).toString(), isNot(contains(sentinel)));
    expect(const RequiredInput.dirty('ordinary text').toString(),
        contains('ordinary text'));
  });
}
