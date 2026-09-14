import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFlavorEnv', () {
    test('isDevelopment/isStaging/isProduction reflect the enum value', () {
      expect(AppFlavorEnv.development.isDevelopment, isTrue);
      expect(AppFlavorEnv.development.isStaging, isFalse);
      expect(AppFlavorEnv.development.isProduction, isFalse);

      expect(AppFlavorEnv.staging.isStaging, isTrue);
      expect(AppFlavorEnv.production.isProduction, isTrue);
    });
  });

  group('AppFlavor', () {
    test('isDevelopment/isStaging/isProduction delegate to env', () {
      const flavor = AppFlavor(env: AppFlavorEnv.staging);
      expect(flavor.isStaging, isTrue);
      expect(flavor.isDevelopment, isFalse);
    });

    test('get returns the typed value for an existing key', () {
      const flavor = AppFlavor(
        env: AppFlavorEnv.production,
        values: {'baseUrl': 'https://api.example.com', 'retries': 3},
      );
      expect(flavor.get<String>('baseUrl'), 'https://api.example.com');
      expect(flavor.get<int>('retries'), 3);
    });

    test('get returns null for a missing key', () {
      const flavor = AppFlavor(env: AppFlavorEnv.production);
      expect(flavor.get<String>('missing'), isNull);
    });

    test('require returns the typed value for an existing key', () {
      const flavor = AppFlavor(
        env: AppFlavorEnv.production,
        values: {'baseUrl': 'https://api.example.com'},
      );
      expect(flavor.require<String>('baseUrl'), 'https://api.example.com');
    });

    test('require throws StateError for a missing key', () {
      const flavor = AppFlavor(env: AppFlavorEnv.production);
      expect(
        () => flavor.require<String>('missing'),
        throwsA(isA<StateError>()),
      );
    });

    test('toString includes env and value keys', () {
      const flavor = AppFlavor(
        env: AppFlavorEnv.staging,
        values: {'baseUrl': 'x'},
      );
      expect(flavor.toString(), contains('staging'));
      expect(flavor.toString(), contains('baseUrl'));
    });
  });
}
