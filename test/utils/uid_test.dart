import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UuidGenerator', () {
    test('v4() returns a well-formed RFC 4122 v4 UUID string', () {
      final id = uuid.v4();

      // 8-4-4-4-12 hex groups, version nibble '4', variant nibble in
      // [8, 9, a, b].
      final v4Pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      expect(id, matches(v4Pattern));
    });

    test('v4() returns distinct values across calls', () {
      final ids = List.generate(1000, (_) => uuid.v4());
      expect(ids.toSet().length, ids.length);
    });
  });
}
