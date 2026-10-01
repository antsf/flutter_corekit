import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

class ContextAdapter implements HttpClientAdapter {
  int requests = 0;
  Future<ResponseBody> Function(RequestOptions)? respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    if (respond != null) return respond!(options);
    return jsonResponse(200, {
      'auth': options.headers['Authorization'],
      'tenant': options.headers['X-Tenant'],
      'uri': options.uri.toString(),
    });
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Object body) =>
    ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

DioClient makeClient(ContextAdapter adapter,
        {Future<String?> Function(Dio)? refresh}) =>
    DioClient(
      baseUrl: 'https://api.test',
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      enableLogging: false,
      refreshToken: refresh,
    );

void main() {
  const ttl = Duration(minutes: 5);

  test('cache partitions effective per-request auth and tenant', () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter)..setAuthToken('global');
    Future<ApiResponse<Map<String, dynamic>>> request(
            String auth, String tenant) =>
        client.get('/me',
            cacheTtl: ttl,
            options: Options(headers: {
              'Authorization': 'Bearer $auth',
              'X-Tenant': tenant,
            }));
    final a = await request('A', 'one');
    final b = await request('B', 'one');
    final b2 = await request('B', 'two');
    expect(a.data?['auth'], 'Bearer A');
    expect(b.data?['auth'], 'Bearer B');
    expect(b2.data?['tenant'], 'two');
    await request('B', 'two');
    expect(adapter.requests, 3);
  });

  test('cache keys distinguish encoded query, response type, and extra context',
      () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter);
    await client.get('/me', cacheTtl: ttl, queryParameters: {'x': '1&y=2'});
    await client
        .get('/me', cacheTtl: ttl, queryParameters: {'x': '1', 'y': '2'});
    await client.get('/me',
        cacheTtl: ttl, options: Options(extra: {'tenant': 'one'}));
    await client.get('/me',
        cacheTtl: ttl, options: Options(extra: {'tenant': 'two'}));
    expect(adapter.requests, 4);
  });

  test('concurrent per-request identities never share a cache entry', () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter);
    Future<ApiResponse<Map<String, dynamic>>> request(String auth) =>
        client.get('/me',
            cacheTtl: ttl,
            options: Options(headers: {'Authorization': 'Bearer $auth'}));
    final results = await Future.wait([request('A'), request('B')]);
    expect(results.map((r) => r.data?['auth']), ['Bearer A', 'Bearer B']);
    expect((await request('A')).data?['auth'], 'Bearer A');
    expect((await request('B')).data?['auth'], 'Bearer B');
  });

  test('interceptors added after construction cannot share identity cache',
      () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter);
    var tenant = 'A';
    client.dioInstance.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      options.headers['X-Tenant'] = tenant;
      handler.next(options);
    }));
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['tenant'],
        'A');
    tenant = 'B';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['tenant'],
        'B');
    expect(adapter.requests, 2);
  });

  test('custom response decoders do not share a raw-response cache', () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter);
    final first = await client.get<String>('/me',
        cacheTtl: ttl,
        options: Options(
            responseType: ResponseType.plain,
            responseDecoder: (_, options, body) => 'account-A'));
    final second = await client.get<String>('/me',
        cacheTtl: ttl,
        options: Options(
            responseType: ResponseType.plain,
            responseDecoder: (_, options, body) => 'account-B'));
    expect(first.data, 'account-A');
    expect(second.data, 'account-B');
    expect(adapter.requests, 2);
  });

  test('cache cannot bypass a different response acceptance policy', () async {
    final adapter = ContextAdapter();
    final client = makeClient(adapter);
    expect(
        (await client.get<Object>('/me', cacheTtl: ttl)).isSuccessful, isTrue);
    final rejected = await client.get<Object>('/me',
        cacheTtl: ttl, options: Options(validateStatus: (_) => false));
    expect(rejected.isFailure, isTrue);
    expect(adapter.requests, 2);
  });

  for (final switchAccount in [false, true]) {
    test(
        '${switchAccount ? 'account switch' : 'logout'} invalidates concurrent refresh waiters',
        () async {
      final started = Completer<void>();
      final release = Completer<String?>();
      final adapter = ContextAdapter()
        ..respond = (o) async => jsonResponse(
            o.headers['Authorization'] == 'Bearer fresh' ? 200 : 401,
            {'ok': true});
      var refreshCalls = 0;
      final client = makeClient(adapter, refresh: (_) {
        refreshCalls++;
        if (!started.isCompleted) started.complete();
        return release.future;
      })
        ..setAuthToken('A');
      final requests = List.generate(3, (_) => client.get('/me'));
      await started.future;
      // Let all 401 handlers join the in-flight refresh.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (switchAccount) {
        client.setAuthToken('B');
      } else {
        client.clearAuthToken();
      }
      release.complete('fresh');
      final results = await Future.wait(requests);
      expect(client.authorizationHeader, switchAccount ? 'Bearer B' : null);
      expect(results.every((r) => r.isFailure), isTrue);
      expect(adapter.requests, 3, reason: 'stale requests must not retry');
      expect(refreshCalls, 1);
    });
  }

  test('delayed old-session 401 cannot start refresh in a new session',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final adapter = ContextAdapter()
      ..respond = (_) async {
        started.complete();
        await release.future;
        return jsonResponse(401, {'error': 'unauthorized'});
      };
    var refreshCalls = 0;
    final client = makeClient(adapter, refresh: (_) async {
      refreshCalls++;
      return 'fresh';
    })
      ..setAuthToken('A');
    final request = client.get('/me');
    await started.future;
    client.setAuthToken('B');
    release.complete();
    expect((await request).isFailure, isTrue);
    expect(refreshCalls, 0);
    expect(client.authorizationHeader, 'Bearer B');
  });

  test('explicit per-request identity does not refresh the global session',
      () async {
    final adapter = ContextAdapter()
      ..respond = (_) async => jsonResponse(401, {'error': 'unauthorized'});
    var refreshCalls = 0;
    final client = makeClient(adapter, refresh: (_) async {
      refreshCalls++;
      return 'fresh';
    })
      ..setAuthToken('A');
    final result = await client.get('/me',
        options: Options(headers: {'Authorization': 'Bearer B'}));
    expect(result.isFailure, isTrue);
    expect(refreshCalls, 0);
    expect(client.authorizationHeader, 'Bearer A');
  });
}
