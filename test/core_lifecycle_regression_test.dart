import 'dart:async';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'mocks/mock_connectivity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockConnectivity connectivity;
  setUp(() async {
    await FlutterCorekit.resetInitialization();
    connectivity = MockConnectivity();
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    ConnectivityService.reset(testConnectivity: connectivity);
  });
  tearDown(() async {
    await FlutterCorekit.resetInitialization();
  });

  test('concurrent initialization joins first caller and publishes once',
      () async {
    final first = FlutterCorekit.initialize(
        baseUrl: 'https://first.test', enableLogging: false);
    final second = FlutterCorekit.initialize(
        baseUrl: 'https://second.test', enableLogging: false);
    await Future.wait([first, second]);
    expect(FlutterCorekit.dioClient.dioInstance.options.baseUrl,
        'https://first.test');
    verify(() => connectivity.checkConnectivity()).called(1);
  });

  test('reset and reinitialize replaces services without late-final errors',
      () async {
    await FlutterCorekit.initialize(
        baseUrl: 'https://first.test', enableLogging: false);
    final oldClient = FlutterCorekit.dioClient;
    final oldStorage = FlutterCorekit.secureStorage;
    oldClient.setAuthToken('OLD_SESSION_SENTINEL');
    await FlutterCorekit.resetInitialization();
    expect(() => FlutterCorekit.dioClient, throwsA(isA<Error>()));
    await FlutterCorekit.initialize(
        baseUrl: 'https://second.test', enableLogging: false);
    expect(FlutterCorekit.dioClient, isNot(same(oldClient)));
    expect(FlutterCorekit.secureStorage, isNot(same(oldStorage)));
    expect(FlutterCorekit.dioClient.dioInstance.options.baseUrl,
        'https://second.test');
    expect(FlutterCorekit.dioClient.authorizationHeader, isNull);
    expect((await oldClient.get<Object>('/after-reset')).isFailure, isTrue);
  });

  test('failed initialization can retry and does not publish partial services',
      () async {
    await expectLater(
        FlutterCorekit.initialize(
            baseUrl: 'https://first.test',
            connectTimeout: -1,
            enableLogging: false),
        throwsStateError);
    expect(() => FlutterCorekit.secureStorage, throwsA(isA<Error>()));
    await FlutterCorekit.initialize(
        baseUrl: 'https://second.test', enableLogging: false);
    expect(FlutterCorekit.dioClient.dioInstance.options.baseUrl,
        'https://second.test');
  });

  test(
      'reset invalidates initialization in flight without clearing the replacement',
      () async {
    final entered = Completer<void>();
    final release = Completer<List<ConnectivityResult>>();
    var calls = 0;
    when(() => connectivity.checkConnectivity()).thenAnswer((_) {
      calls++;
      if (calls == 1) {
        entered.complete();
        return release.future;
      }
      return Future.value([ConnectivityResult.wifi]);
    });
    final stale = FlutterCorekit.initialize(
        baseUrl: 'https://stale.test', enableLogging: false);
    final staleExpectation = expectLater(stale, throwsStateError);
    await entered.future;
    await FlutterCorekit.resetInitialization();
    await FlutterCorekit.initialize(
        baseUrl: 'https://replacement.test', enableLogging: false);
    final replacement = FlutterCorekit.dioClient;
    release.complete([ConnectivityResult.wifi]);
    await staleExpectation;
    expect(FlutterCorekit.dioClient, same(replacement));
    expect(replacement.dioInstance.options.baseUrl, 'https://replacement.test');
  });
}
