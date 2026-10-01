import 'dart:async';

import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_isolation_regression_test.dart'
    show ContextAdapter, jsonResponse;

class AccountTransformer extends SyncTransformer {
  final String Function() account;
  AccountTransformer(this.account);
  @override
  Future<dynamic> transformResponse(
      RequestOptions options, ResponseBody body) async {
    await body.stream.drain<void>();
    return {'account': account()};
  }
}

void main() {
  const ttl = Duration(minutes: 1);
  DioClient clientFor(ContextAdapter adapter) => DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        enableLogging: false,
      );

  test('SUP-05 transformer replacement rejects an old in-flight cache write',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var calls = 0;
    final adapter = ContextAdapter()
      ..respond = (_) async {
        calls++;
        if (calls == 1) {
          started.complete();
          await release.future;
          return jsonResponse(200, {'account': 'A'});
        }
        return jsonResponse(200, {'account': 'B'});
      };
    final client = clientFor(adapter);
    final old = client.get<Map<String, dynamic>>('/me', cacheTtl: ttl);
    await started.future;
    client.dioInstance.transformer = SyncTransformer();
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'B');
    release.complete();
    await old;
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'B');
    expect(adapter.requests, 2);
  });

  test('SUP-05 custom transformer closure context cannot share cache',
      () async {
    var account = 'A';
    final adapter = ContextAdapter();
    final client = clientFor(adapter);
    client.dioInstance.transformer = AccountTransformer(() => account);
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'A');
    account = 'B';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'B');
    expect(adapter.requests, 2);
  });

  test(
      'SUP-05 mutable default transformer callbacks bypass and invalidate cache',
      () async {
    var account = 'A';
    final adapter = ContextAdapter()
      ..respond = (_) async => jsonResponse(200, {'account': account});
    final client = clientFor(adapter);
    final transformer = SyncTransformer();
    client.dioInstance.transformer = transformer;
    final originalDecoder = transformer.jsonDecodeCallback;
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'A');
    transformer.jsonDecodeCallback = (_) => {'account': account};
    account = 'B';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'B');
    transformer.jsonDecodeCallback = originalDecoder;
    account = 'C';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'C');
    expect(adapter.requests, 3);
  });

  test('SUP-05 replaced then restored transformer does not revive old entries',
      () async {
    var account = 'A';
    final adapter = ContextAdapter()
      ..respond = (_) async => jsonResponse(200, {'account': account});
    final client = clientFor(adapter);
    final original = client.dioInstance.transformer;
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'A');
    client.dioInstance.transformer = AccountTransformer(() => account);
    account = 'B';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'B');
    client.dioInstance.transformer = original;
    account = 'C';
    expect(
        (await client.get<Map<String, dynamic>>('/me', cacheTtl: ttl))
            .data?['account'],
        'C');
    await client.get('/me', cacheTtl: ttl);
    expect(adapter.requests, 3);
  });
}
