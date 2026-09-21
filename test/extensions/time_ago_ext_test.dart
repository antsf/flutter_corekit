import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeAgoExt', () {
    test('timeAgo formats a fixed "now" relative to a pinned clock', () {
      final now = DateTime(2025, 6, 26, 12, 0, 0);
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      expect(fiveMinutesAgo.timeAgo(clock: now), '5 minutes ago');
    });

    test('timeAgo formats a moment just now', () {
      final now = DateTime(2025, 6, 26, 12, 0, 0);
      expect(now.timeAgo(clock: now), 'a moment ago');
    });

    test('timeAgo formats days ago', () {
      final now = DateTime(2025, 6, 26, 12, 0, 0);
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      expect(threeDaysAgo.timeAgo(clock: now), '3 days ago');
    });

    test('timeAgoShort formats using the short-form locale', () {
      final now = DateTime(2025, 6, 26, 12, 0, 0);
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      expect(twoHoursAgo.timeAgoShort(clock: now), '2h');
    });
  });
}
