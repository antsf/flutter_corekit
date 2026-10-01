import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'logging_privacy_regression_test.dart' show AllowLogs, CaptureOutput;
import 'session_isolation_regression_test.dart'
    show ContextAdapter, jsonResponse;

class MockDio extends Mock implements Dio {}

class MockConnectivity extends Mock implements ConnectivityService {}

void main() {
  const sentinel = 'SYNTHETIC_SECRET_NEVER_REAL';
  late CaptureOutput output;
  late Logger logger;
  setUp(() {
    output = CaptureOutput();
    logger = Logger(
        filter: AllowLogs(),
        printer: SimplePrinter(colors: false),
        output: output);
  });
  tearDown(() async => logger.close());
  void privateLogs() {
    expect(output.lines, isNotEmpty);
    expect(output.lines.join('\n'), isNot(contains(sentinel)));
  }

  test('PRIVACY diagnostic sink failure never masks the network outcome',
      () async {
    final broken = Logger(
        filter: AllowLogs(),
        printer: SimplePrinter(colors: false),
        output: CaptureOutput());
    await broken.close();
    final adapter = ContextAdapter()
      ..respond = (_) async => jsonResponse(503, {'message': 'retry'});
    final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        logger: broken,
        retryOptions: const RetryOptions(
            maxAttempts: 2, baseDelayMs: 0, maxDelayMs: 0, useJitter: false));
    final response =
        await client.get('/me').timeout(const Duration(seconds: 2));
    expect(response.error, isA<ServiceUnavailableException>());
    expect(adapter.requests, 2);
  });
  test('PRIVACY retry and exhaustion omit raw URI; retain request and failure',
      () async {
    final auths = <Object?>[];
    final paths = <String>[];
    final adapter = ContextAdapter()
      ..respond = (o) async {
        auths.add(o.headers['Authorization']);
        paths.add(o.path);
        return jsonResponse(503, {'message': sentinel});
      };
    final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        logger: logger,
        retryOptions: const RetryOptions(
            maxAttempts: 2, baseDelayMs: 0, maxDelayMs: 0, useJitter: false));
    const path = 'https://user:$sentinel@api.test/$sentinel?token=$sentinel';
    final options = Options(headers: {'Authorization': 'Bearer $sentinel'});
    final response = await client.get(path, options: options);
    expect(response.isFailure, isTrue);
    expect(response.error, isA<ServiceUnavailableException>());
    expect(auths, ['Bearer $sentinel', 'Bearer $sentinel']);
    expect(paths, [path, path]);
    expect(options.headers?['Authorization'], 'Bearer $sentinel');
    privateLogs();
  });
  test('PRIVACY parsing omits raw exception and stack; retains typed failure',
      () async {
    final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = ContextAdapter(),
        logger: logger);
    final response = await client.get<Object>('/me',
        fromJson: (_) => Error.throwWithStackTrace(
            StateError(sentinel), StackTrace.fromString(sentinel)));
    expect(response.isFailure, isTrue);
    expect(response.error, isA<UnknownNetworkException>());
    privateLogs();
  });
  test('PRIVACY unexpected failure omits raw exception and stack', () async {
    final conn = MockConnectivity();
    when(() => conn.hasConnection()).thenAnswer((_) =>
        Future.error(StateError(sentinel), StackTrace.fromString(sentinel)));
    final client = DioClient(
        baseUrl: 'https://api.test',
        connectivityService: conn,
        checkConnectivityBeforeRequest: true,
        logger: logger);
    final response = await client.get('/me');
    expect(response.isFailure, isTrue);
    expect(response.error, isA<UnknownNetworkException>());
    privateLogs();
  });
  test('PRIVACY download logging omits exception and preserves returned error',
      () async {
    final dio = MockDio();
    when(() => dio.options)
        .thenReturn(BaseOptions(baseUrl: 'https://api.test'));
    when(() => dio.interceptors).thenReturn(Interceptors());
    final original = StateError(sentinel);
    when(() => dio.download(any(), any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress')))
        .thenAnswer(
            (_) => Future.error(original, StackTrace.fromString(sentinel)));
    final client =
        DioClient(baseUrl: 'https://api.test', dio: dio, logger: logger);
    await expectLater(
        client.download('/file', savePath: 'unused-synthetic-file'),
        throwsA(isA<UnknownNetworkException>()));
    privateLogs();
  });
  test('PRIVACY refresh logging omits exception and preserves 401 failure',
      () async {
    final adapter = ContextAdapter()
      ..respond = (_) async => jsonResponse(401, {'message': 'unauthorized'});
    final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        logger: logger,
        refreshToken: (_) =>
            Future.error(StateError(sentinel), StackTrace.fromString(sentinel)))
      ..setAuthToken('old');
    final response = await client.get('/me');
    expect(response.isFailure, isTrue);
    expect(response.error, isA<UnauthorizedException>());
    expect(client.authorizationHeader, 'Bearer old');
    expect(adapter.requests, 1);
    privateLogs();
  });
}
