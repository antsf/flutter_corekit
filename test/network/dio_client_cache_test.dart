import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockDio dio;
  late MockConnectivityService conn;
  late BaseOptions baseOptions;
  late Interceptors interceptors;
  late int getCount;

  const ttl = Duration(minutes: 5);

  Response<dynamic> okResponse(String path) => Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        data: {'value': 1},
        statusCode: 200,
      );

  setUp(() {
    dio = MockDio();
    conn = MockConnectivityService();
    baseOptions = BaseOptions(baseUrl: 'https://api.test');
    interceptors = Interceptors();
    getCount = 0;

    when(() => dio.options).thenReturn(baseOptions);
    when(() => dio.interceptors).thenReturn(interceptors);
    when(() => dio.transformer).thenReturn(FusedTransformer());
    when(() => conn.hasConnection()).thenAnswer((_) async => true);
    when(() => dio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((inv) async {
      getCount++;
      return okResponse(inv.positionalArguments.first as String);
    });
  });

  DioClient client({int maxCacheEntries = 100}) => DioClient(
        baseUrl: 'https://api.test',
        dio: dio,
        connectivityService: conn,
        enableLogging: false,
        maxCacheEntries: maxCacheEntries,
      );

  test('cache is scoped per identity — token change does not leak (M5)',
      () async {
    final c = client();

    c.setAuthToken('user-A');
    await c.get('/me', cacheTtl: ttl); // network
    await c.get('/me', cacheTtl: ttl); // cache hit
    expect(getCount, 1, reason: 'second call for user A should be cached');

    c.setAuthToken('user-B');
    await c.get('/me', cacheTtl: ttl); // different identity -> must hit network
    expect(getCount, 2, reason: "user B must not see user A's cached response");
  });

  test('cache is bounded with LRU eviction (M5)', () async {
    final c = client(maxCacheEntries: 2);
    c.setAuthToken('user-A');

    await c.get('/a', cacheTtl: ttl); // count 1, cache {a}
    await c.get('/b', cacheTtl: ttl); // count 2, cache {a,b}
    await c.get('/c', cacheTtl: ttl); // count 3, cache {b,c} (a evicted)

    await c.get('/c', cacheTtl: ttl); // cache hit -> still 3
    expect(getCount, 3, reason: '/c should still be cached');

    await c.get('/a', cacheTtl: ttl); // evicted earlier -> network, count 4
    expect(getCount, 4, reason: '/a should have been evicted (LRU)');
  });

  test('forceRefresh bypasses a valid cache entry', () async {
    final c = client();
    c.setAuthToken('user-A');

    await c.get('/x', cacheTtl: ttl); // count 1
    await c.get('/x', cacheTtl: ttl); // cache hit -> 1
    expect(getCount, 1);

    await c.get('/x', cacheTtl: ttl, forceRefresh: true); // bypass -> 2
    expect(getCount, 2);
  });

  test('connectivity pre-flight is OFF by default (M3)', () async {
    // Offline per the connectivity service...
    when(() => conn.hasConnection()).thenAnswer((_) async => false);
    final c = client(); // default: checkConnectivityBeforeRequest = false

    final result = await c.get('/x');

    // ...but the request still proceeds (no unreliable pre-flight blocking it),
    // and connectivity is never consulted.
    expect(result.isSuccessful, isTrue);
    verifyNever(() => conn.hasConnection());
  });
}
