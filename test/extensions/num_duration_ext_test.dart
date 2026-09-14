import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumDurationExt', () {
    test('microseconds rounds to the nearest microsecond', () {
      expect(1.microseconds, const Duration(microseconds: 1));
      expect(1.6.microseconds, const Duration(microseconds: 2));
    });

    test('ms and milliseconds are equivalent and correct', () {
      expect(200.ms, const Duration(milliseconds: 200));
      expect(200.milliseconds, const Duration(milliseconds: 200));
    });

    test('seconds converts correctly', () {
      expect(3.seconds, const Duration(seconds: 3));
    });

    test('minutes converts correctly', () {
      expect(2.minutes, const Duration(minutes: 2));
    });

    test('hours converts correctly', () {
      expect(1.hours, const Duration(hours: 1));
    });

    test('days converts correctly', () {
      expect(1.days, const Duration(days: 1));
    });

    test('fractional values convert correctly', () {
      expect(1.5.minutes, const Duration(seconds: 90));
      expect(0.5.seconds, const Duration(milliseconds: 500));
    });
  });
}
