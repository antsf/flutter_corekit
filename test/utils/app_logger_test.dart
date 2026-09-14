import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app_logger', () {
    // These simply verify each helper runs without throwing for the common
    // parameter combinations; the underlying `logger` package owns output
    // formatting/behavior.
    test('logE runs without throwing', () {
      expect(() => logE('error message'), returnsNormally);
      expect(
        () => logE('error with details',
            error: Exception('boom'), stackTrace: StackTrace.current),
        returnsNormally,
      );
    });

    test('logW runs without throwing', () {
      expect(() => logW('warning message'), returnsNormally);
    });

    test('logI runs without throwing', () {
      expect(() => logI('info message'), returnsNormally);
    });

    test('logD runs without throwing', () {
      expect(() => logD('debug message'), returnsNormally);
    });
  });
}
