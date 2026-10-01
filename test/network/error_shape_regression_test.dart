import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_isolation_regression_test.dart'
    show ContextAdapter, jsonResponse, makeClient;

void main() {
  for (final key in ['message', 'error']) {
    for (final value in <Object>[
      {'code': 'bad'},
      ['bad'],
      42,
      true
    ]) {
      test('$key ${value.runtimeType} returns typed failures on both safe APIs',
          () async {
        final body = {key: value};
        final adapter = ContextAdapter()
          ..respond = (_) async => jsonResponse(400, body);
        final response = await makeClient(adapter).get<Object>('/bad');
        expect(response.isFailure, isTrue);
        expect(response.error, isA<ClientErrorException>());
        final options = RequestOptions(path: '/bad');
        final error = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Object>(
              requestOptions: options, statusCode: 400, data: body),
        );
        final result = await safeRemoteCall<Object, Object>(
            remoteCall: () async => throw error);
        expect(result.isFailure, isTrue);
        expect(result.failure, isA<ClientErrorException>());
      });
    }
  }

  test('valid string error remains available when message has another type',
      () async {
    final adapter = ContextAdapter()
      ..respond = (_) async =>
          jsonResponse(400, {'message': [], 'error': 'Readable failure'});
    final response = await makeClient(adapter).get<Object>('/bad');
    expect(response.error?.message, 'Readable failure');
  });
}
