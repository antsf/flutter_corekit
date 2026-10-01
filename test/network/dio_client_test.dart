import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_corekit/src/network/dio_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockLogger extends Mock implements Logger {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late DioClient dioClient;
  late MockDio mockDio;
  late MockConnectivityService mockConnectivityService;
  late MockLogger mockLogger;
  late BaseOptions baseOptions;
  late Interceptors interceptors;

  const baseUrl = 'https://api.example.com';
  const connectTimeoutMs = 15000;
  const receiveTimeoutMs = 15000;

  setUpAll(() {
    registerFallbackValue(Uri.parse(baseUrl));
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(CancelToken());
    registerFallbackValue(Options());
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(
        DioException(requestOptions: RequestOptions(path: '')));
  });

  setUp(() {
    mockDio = MockDio();
    mockConnectivityService = MockConnectivityService();
    mockLogger = MockLogger();
    interceptors = Interceptors();

    baseOptions = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: receiveTimeoutMs),
    );
    when(() => mockDio.options).thenReturn(baseOptions);
    when(() => mockDio.interceptors).thenReturn(interceptors);
    when(() => mockDio.transformer).thenReturn(FusedTransformer());

    dioClient = DioClient(
      baseUrl: baseUrl,
      dio: mockDio,
      connectivityService: mockConnectivityService,
      logger: mockLogger,
      enableLogging: true,
      // Connectivity pre-flight is opt-in (default off); enable it here so the
      // existing connectivity tests below exercise that path.
      checkConnectivityBeforeRequest: true,
      refreshToken: (dio) async => 'new_refreshed_token',
    );
  });

  group('DioClient Initialization', () {
    test('should initialize Dio with correct base URL and timeouts', () {
      expect(dioClient.dioInstance.options.baseUrl, baseUrl);
      expect(
        dioClient.dioInstance.options.connectTimeout,
        const Duration(milliseconds: connectTimeoutMs),
      );
      expect(
        dioClient.dioInstance.options.receiveTimeout,
        const Duration(milliseconds: receiveTimeoutMs),
      );
    });

    test('should add logging interceptor when enableLogging is true', () {
      expect(
        dioClient.dioInstance.interceptors
            .any((i) => i is DioLoggingInterceptor),
        isTrue,
      );
    });

    test('should add token refresh interceptor when refreshToken is provided',
        () {
      expect(
        dioClient.dioInstance.interceptors.any((i) => i is InterceptorsWrapper),
        isTrue,
      );
    });
  });

  group('HTTP Requests', () {
    const testPath = '/test';
    final testBody = {'key': 'value'};
    final testResponseData = {'result': 'success'};
    final response = Response(
      requestOptions: RequestOptions(path: testPath),
      data: testResponseData,
      statusCode: 200,
    );

    setUp(() {
      when(() => mockConnectivityService.hasConnection())
          .thenAnswer((_) async => true);
    });

    test('GET returns ApiResponse.success with response data', () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.get(testPath);

      expect(result.isSuccessful, isTrue);
      expect(result.data, testResponseData);
      verify(() => mockDio.get(testPath, options: any(named: 'options')))
          .called(1);
    });

    test('GET with fromJson maps response data', () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.get<String>(
        testPath,
        fromJson: (d) => d['result'] as String,
      );

      expect(result.isSuccessful, isTrue);
      expect(result.data, 'success');
    });

    test('POST returns ApiResponse.success', () async {
      when(() => mockDio.post(
            testPath,
            data: testBody,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.post(testPath, body: testBody);

      expect(result.isSuccessful, isTrue);
      expect(result.data, testResponseData);
      verify(() => mockDio.post(testPath,
          data: testBody, options: any(named: 'options'))).called(1);
    });

    test('PUT returns ApiResponse.success', () async {
      when(() => mockDio.put(
            testPath,
            data: testBody,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.put(testPath, body: testBody);

      expect(result.isSuccessful, isTrue);
      expect(result.data, testResponseData);
      verify(() => mockDio.put(testPath,
          data: testBody, options: any(named: 'options'))).called(1);
    });

    test('DELETE returns ApiResponse.success', () async {
      when(() => mockDio.delete(
            testPath,
            data: testBody,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.delete(testPath, body: testBody);

      expect(result.isSuccessful, isTrue);
      expect(result.data, testResponseData);
      verify(() => mockDio.delete(testPath,
          data: testBody, options: any(named: 'options'))).called(1);
    });

    test('PATCH returns ApiResponse.success', () async {
      when(() => mockDio.patch(
            testPath,
            data: testBody,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final result = await dioClient.patch(testPath, body: testBody);

      expect(result.isSuccessful, isTrue);
      expect(result.data, testResponseData);
      verify(() => mockDio.patch(testPath,
          data: testBody, options: any(named: 'options'))).called(1);
    });

    test('null response body returns ApiResponse.success with null data',
        () async {
      final nullResponse = Response(
        requestOptions: RequestOptions(path: testPath),
        data: null,
        statusCode: 204,
      );

      when(() => mockDio.post(
            testPath,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => nullResponse);

      final result = await dioClient.post(testPath, body: testBody);

      expect(result.isSuccessful, isTrue);
      expect(result.data, isNull);
    });
  });

  group('Cache', () {
    const testPath = '/users';
    final responseData = {'id': 1, 'name': 'Andi'};
    final response = Response(
      requestOptions: RequestOptions(path: testPath),
      data: responseData,
      statusCode: 200,
    );

    setUp(() {
      when(() => mockConnectivityService.hasConnection())
          .thenAnswer((_) async => true);
    });

    test('second GET with cacheTtl uses cached data without network call',
        () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      final first =
          await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));
      final second =
          await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));

      expect(first.isSuccessful, isTrue);
      expect(second.isSuccessful, isTrue);
      expect(second.data, responseData);
      // Only one real network call
      verify(() => mockDio.get(testPath, options: any(named: 'options')))
          .called(1);
    });

    test('forceRefresh bypasses cache', () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));
      await dioClient.get(testPath,
          cacheTtl: const Duration(minutes: 5), forceRefresh: true);

      verify(() => mockDio.get(testPath, options: any(named: 'options')))
          .called(2);
    });

    test('clearCache removes all entries', () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));
      dioClient.clearCache();
      await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));

      verify(() => mockDio.get(testPath, options: any(named: 'options')))
          .called(2);
    });

    test('invalidateCache removes specific entry', () async {
      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => response);

      await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));
      dioClient.invalidateCache(testPath);
      await dioClient.get(testPath, cacheTtl: const Duration(minutes: 5));

      verify(() => mockDio.get(testPath, options: any(named: 'options')))
          .called(2);
    });
  });

  group('Error Handling', () {
    const testPath = '/test';

    setUp(() {
      when(() => mockConnectivityService.hasConnection())
          .thenAnswer((_) async => true);
    });

    test('returns ApiResponse.failure with NoInternetConnectionException',
        () async {
      when(() => mockConnectivityService.hasConnection())
          .thenAnswer((_) async => false);

      final result = await dioClient.get(testPath);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NoInternetConnectionException>());
    });

    test('returns ApiResponse.failure with UnauthorizedException for 401',
        () async {
      final errorResponse = Response(
        requestOptions: RequestOptions(path: testPath),
        statusCode: 401,
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: testPath),
        response: errorResponse,
        type: DioExceptionType.badResponse,
      );

      dioClient = DioClient(
        baseUrl: baseUrl,
        dio: mockDio,
        connectivityService: mockConnectivityService,
        logger: mockLogger,
        enableLogging: false,
      );

      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(dioException);

      final result = await dioClient.get(testPath);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<UnauthorizedException>());
    });

    test(
        'returns ApiResponse.failure with NetworkTimeoutException on connection timeout',
        () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: testPath),
        type: DioExceptionType.connectionTimeout,
      );

      when(() => mockDio.get(
            testPath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(dioException);

      final result = await dioClient.get(testPath);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkTimeoutException>());
    });
  });

  group('Header Management', () {
    test('adds and retrieves auth token correctly', () {
      dioClient.setAuthToken('test_token');
      expect(dioClient.authorizationHeader, 'Bearer test_token');
    });

    test('adds custom header', () {
      dioClient.addHeader('Custom-Header', 'value');
      expect(dioClient.dioInstance.options.headers['Custom-Header'], 'value');
    });

    test('removes header', () {
      dioClient.addHeader('Custom-Header', 'value');
      dioClient.removeHeader('Custom-Header');
      expect(dioClient.dioInstance.options.headers.containsKey('Custom-Header'),
          isFalse);
    });

    test('clears all headers', () {
      dioClient.addHeader('Header1', 'value1');
      dioClient.addHeader('Header2', 'value2');
      dioClient.clearHeaders();
      expect(dioClient.dioInstance.options.headers.isEmpty, isTrue);
    });

    test('clears auth token', () {
      dioClient.setAuthToken('test_token');
      dioClient.clearAuthToken();
      expect(dioClient.authorizationHeader, isNull);
    });
  });

  group('DioLoggingInterceptor', () {
    const testPath = '/test';
    final testRequestOptions = RequestOptions(path: testPath);
    final testResponse = Response(
      requestOptions: testRequestOptions,
      data: {'result': 'success'},
      statusCode: 200,
    );
    final dioException = DioException(
      requestOptions: testRequestOptions,
      response: Response(
        requestOptions: testRequestOptions,
        statusCode: 400,
        statusMessage: 'Bad Request',
      ),
      type: DioExceptionType.badResponse,
      stackTrace: StackTrace.current,
    );

    setUp(() {
      when(() => mockLogger.e(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          )).thenReturn(null);
    });

    test('logs request details', () {
      final interceptor =
          DioLoggingInterceptor(logger: mockLogger, enableLogging: true);
      interceptor.onRequest(testRequestOptions, RequestInterceptorHandler());

      verify(() => mockLogger.i(any())).called(1);
    });

    test('logs response details', () {
      final interceptor =
          DioLoggingInterceptor(logger: mockLogger, enableLogging: true);
      interceptor.onResponse(testResponse, ResponseInterceptorHandler());

      verify(() => mockLogger.i(any())).called(1);
    });

    test('logs error details', () {
      final interceptor =
          DioLoggingInterceptor(logger: mockLogger, enableLogging: true);
      final handler = MockErrorInterceptorHandler();
      when(() => handler.next(any())).thenAnswer((_) {});

      interceptor.onError(dioException, handler);

      verify(() => mockLogger.e(
            any(that: contains('Status Code: 400')),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          )).called(1);
      verify(() => handler.next(dioException)).called(1);
    });

    test('does not log when enableLogging is false', () {
      final interceptor =
          DioLoggingInterceptor(logger: mockLogger, enableLogging: false);
      final handler = MockErrorInterceptorHandler();
      when(() => handler.next(any())).thenAnswer((_) {});

      interceptor.onRequest(testRequestOptions, RequestInterceptorHandler());
      interceptor.onResponse(testResponse, ResponseInterceptorHandler());
      interceptor.onError(dioException, handler);

      verifyNever(() => mockLogger.i(any()));
      verifyNever(() => mockLogger.e(any(),
          error: any(named: 'error'), stackTrace: any(named: 'stackTrace')));
      verify(() => handler.next(dioException)).called(1);
    });
  });

  group('Download', () {
    const urlPath = '/download';
    const savePath = 'file_path';

    setUp(() {
      when(() => mockConnectivityService.hasConnection())
          .thenAnswer((_) async => true);
    });

    test('downloads file successfully', () async {
      when(() => mockDio.download(
                urlPath,
                savePath,
                queryParameters: any(named: 'queryParameters'),
                options: any(named: 'options'),
                cancelToken: any(named: 'cancelToken'),
                onReceiveProgress: any(named: 'onReceiveProgress'),
              ))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions()));

      await dioClient.download(urlPath, savePath: savePath);

      verify(() => mockDio.download(urlPath, savePath,
          options: any(named: 'options'))).called(1);
    });

    test('throws NetworkException on download failure', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: urlPath),
        type: DioExceptionType.connectionError,
      );

      when(() => mockDio.download(
            urlPath,
            savePath,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(dioException);

      expect(
        () => dioClient.download(urlPath, savePath: savePath),
        throwsA(isA<NoInternetConnectionException>()),
      );
    });
  });
}
