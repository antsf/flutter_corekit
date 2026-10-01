import 'dart:async';

import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import 'logging_privacy_regression_test.dart' show AllowLogs, CaptureOutput;
import 'session_isolation_regression_test.dart'
    show ContextAdapter, jsonResponse;

class SignalOutput extends CaptureOutput {
  final backoff = Completer<void>();
  @override
  void output(OutputEvent event) {
    super.output(event);
    if (event.lines.any((line) => line.contains('Retrying')) &&
        !backoff.isCompleted) {
      backoff.complete();
    }
  }
}

void main() {
  test('SUP-N01 cancelled token rejects both cache hit and miss', () async {
    final adapter = ContextAdapter();
    final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        enableLogging: false);
    const ttl = Duration(minutes: 1);
    await client.get('/cached', cacheTtl: ttl);
    final cancelled = CancelToken()..cancel('synthetic disposed screen');
    for (final path in ['/cached', '/uncached']) {
      final result =
          await client.get(path, cacheTtl: ttl, cancelToken: cancelled);
      expect(result.isFailure, isTrue);
      expect(result.error, isA<CancelledException>());
    }
    expect(adapter.requests, 1);
  });
  group('SUP-03', () {
    test('delayed same-session 401 uses rotated token without second refresh',
        () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var refreshCalls = 0;
      final auths = <String>[];
      final adapter = ContextAdapter()
        ..respond = (o) async {
          final auth = o.headers['Authorization'];
          auths.add('${o.path}:$auth');
          if (o.path == '/slow' && auth == 'Bearer old') {
            started.complete();
            await release.future;
          }
          return jsonResponse(auth == 'Bearer fresh' ? 200 : 401, {'ok': true});
        };
      final client = DioClient(
          baseUrl: 'https://api.test',
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
          enableLogging: false,
          refreshToken: (_) async {
            refreshCalls++;
            return 'fresh';
          })
        ..setAuthToken('old');
      final slow = client.get('/slow');
      await started.future;
      expect((await client.get('/fast')).isSuccessful, isTrue);
      release.complete();
      expect((await slow).isSuccessful, isTrue);
      expect(refreshCalls, 1);
      expect(auths, [
        '/slow:Bearer old',
        '/fast:Bearer old',
        '/fast:Bearer fresh',
        '/slow:Bearer fresh'
      ]);
    });
    test('explicit matching request auth is not a managed session credential',
        () async {
      var refreshCalls = 0;
      final adapter = ContextAdapter()
        ..respond = (_) async => jsonResponse(401, {'message': 'denied'});
      final client = DioClient(
          baseUrl: 'https://api.test',
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
          enableLogging: false,
          refreshToken: (_) async {
            refreshCalls++;
            return 'fresh';
          })
        ..setAuthToken('old');
      expect(
          (await client.get('/me',
                  options: Options(headers: {'Authorization': 'Bearer old'})))
              .isFailure,
          isTrue);
      expect(refreshCalls, 0);
      expect(adapter.requests, 1);
      expect(client.authorizationHeader, 'Bearer old');
    });
    test('persistent 401 after token rotation remains bounded', () async {
      var refreshCalls = 0;
      final adapter = ContextAdapter()
        ..respond = (_) async => jsonResponse(401, {'message': 'denied'});
      final client = DioClient(
          baseUrl: 'https://api.test',
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
          enableLogging: false,
          refreshToken: (_) async {
            refreshCalls++;
            return 'fresh';
          })
        ..setAuthToken('old');
      expect((await client.get('/me')).isFailure, isTrue);
      expect(refreshCalls, 1);
      expect(adapter.requests, 2);
    });
  });
  test('SUP-02 synchronous refresh failure recovers on next request', () async {
    var refreshCalls = 0;
    final adapter = ContextAdapter()
      ..respond = (o) async => jsonResponse(
          o.headers['Authorization'] == 'Bearer fresh' ? 200 : 401,
          {'ok': true});
    final client = DioClient(
      baseUrl: 'https://api.test',
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      enableLogging: false,
      refreshToken: (_) {
        refreshCalls++;
        if (refreshCalls == 1) throw StateError('synthetic sync failure');
        return Future.value('fresh');
      },
    )..setAuthToken('old');
    expect((await client.get('/me')).isFailure, isTrue);
    expect((await client.get('/me')).isSuccessful, isTrue);
    expect(refreshCalls, 2);
    expect(client.authorizationHeader, 'Bearer fresh');
  });
  group('SUP-01', () {
    for (final switchAccount in [false, true]) {
      test(
          'rejects immediate ${switchAccount ? 'switch' : 'logout'} before interceptors',
          () async {
        final adapter = ContextAdapter()
          ..respond = (_) async => jsonResponse(503, {'message': 'retry'});
        final client = DioClient(
          baseUrl: 'https://api.test',
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
          enableLogging: false,
          retryOptions: const RetryOptions(
              maxAttempts: 2, baseDelayMs: 0, maxDelayMs: 0, useJitter: false),
        )..setAuthToken('A');
        final pending = client.get('/me');
        switchAccount ? client.setAuthToken('B') : client.clearAuthToken();
        expect((await pending).isFailure, isTrue);
        expect(adapter.requests, 0,
            reason: 'stale credentials must never reach the adapter');
      });
    }
    for (final switchAccount in [false, true]) {
      test('blocks retry after ${switchAccount ? 'switch' : 'logout'}',
          () async {
        final started = Completer<void>();
        final release = Completer<void>();
        final auths = <Object?>[];
        final adapter = ContextAdapter()
          ..respond = (o) async {
            auths.add(o.headers['Authorization']);
            if (auths.length == 1) {
              started.complete();
              await release.future;
              return jsonResponse(503, {'message': 'retry'});
            }
            return jsonResponse(200, {'account': 'A'});
          };
        final client = DioClient(
          baseUrl: 'https://api.test',
          dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
            ..httpClientAdapter = adapter,
          enableLogging: false,
          retryOptions: const RetryOptions(
              maxAttempts: 2, baseDelayMs: 0, maxDelayMs: 0, useJitter: false),
        )..setAuthToken('A');
        final pending = client.get('/me');
        await started.future;
        if (switchAccount) {
          client.setAuthToken('B');
        } else {
          client.clearAuthToken();
        }
        release.complete();
        expect((await pending).isFailure, isTrue);
        expect(auths, ['Bearer A']);
      });
    }

    test('checks session again after backoff', () async {
      final output = SignalOutput();
      final logger = Logger(
          filter: AllowLogs(),
          printer: SimplePrinter(colors: false),
          output: output);
      final adapter = ContextAdapter()
        ..respond = (_) async => jsonResponse(503, {'message': 'retry'});
      final client = DioClient(
        baseUrl: 'https://api.test',
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        logger: logger,
        retryOptions: const RetryOptions(
            maxAttempts: 3, baseDelayMs: 50, maxDelayMs: 50, useJitter: false),
      )..setAuthToken('A');
      final pending = client.get('/me');
      await output.backoff.future;
      client.setAuthToken('B');
      expect((await pending).isFailure, isTrue);
      expect(adapter.requests, 1);
      await logger.close();
    });

    for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']) {
      test('rejects stale successful $method completion', () async {
        final started = Completer<void>();
        final release = Completer<void>();
        final adapter = ContextAdapter()
          ..respond = (_) async {
            started.complete();
            await release.future;
            return jsonResponse(200, {'account': 'A'});
          };
        final client = DioClient(
            baseUrl: 'https://api.test',
            dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
              ..httpClientAdapter = adapter,
            enableLogging: false)
          ..setAuthToken('A');
        final Future<ApiResponse<dynamic>> pending = switch (method) {
          'POST' => client.post('/me'),
          'PUT' => client.put('/me'),
          'PATCH' => client.patch('/me'),
          'DELETE' => client.delete('/me'),
          _ => client.get('/me', cacheTtl: const Duration(minutes: 1)),
        };
        await started.future;
        client.setAuthToken('B');
        release.complete();
        final result = await pending;
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
      });
    }
  });
}
