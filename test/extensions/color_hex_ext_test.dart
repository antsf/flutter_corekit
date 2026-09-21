import 'package:flutter/material.dart';
import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorHexExt', () {
    test('toColor parses a 6-digit hex string as opaque', () {
      expect('#FF5733'.toColor(), const Color(0xFFFF5733));
    });

    test('toColor accepts a hex string without a leading #', () {
      expect('FF5733'.toColor(), const Color(0xFFFF5733));
    });

    test('toColor parses an 8-digit AARRGGBB string', () {
      expect('80FF5733'.toColor(), const Color(0x80FF5733));
    });

    test('toColor is case-insensitive', () {
      expect('#ff5733'.toColor(), const Color(0xFFFF5733));
    });

    test('toColor returns null for an invalid length', () {
      expect('FFF'.toColor(), isNull);
    });

    test('toColor returns null for non-hex characters', () {
      expect('not-a-color'.toColor(), isNull);
    });
  });

  group('ColorToHexExt', () {
    test('toHex returns #AARRGGBB by default', () {
      expect(const Color(0xFFFF5733).toHex(), '#FFFF5733');
    });

    test('toHex omits alpha when includeAlpha is false', () {
      expect(
        const Color(0xFFFF5733).toHex(includeAlpha: false),
        '#FF5733',
      );
    });

    test('toHex round-trips through toColor', () {
      const original = Color(0x80112233);
      final hex = original.toHex();
      expect(hex.toColor(), original);
    });
  });
}
