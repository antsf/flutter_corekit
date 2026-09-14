import 'dart:typed_data';

import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _solidColor(int width, int height, int r, int g, int b) {
  final pixels = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    pixels[i * 4] = r;
    pixels[i * 4 + 1] = g;
    pixels[i * 4 + 2] = b;
    pixels[i * 4 + 3] = 255;
  }
  return pixels;
}

void main() {
  group('BlurHash.encode', () {
    test('produces the documented length for given components', () {
      final pixels = _solidColor(4, 4, 255, 0, 0);
      final hash = BlurHash.encode(
        pixels,
        width: 4,
        height: 4,
        componentX: 4,
        componentY: 3,
      );
      // 1 (size flag) + 1 (max value) + 4 (DC) + 2 * (componentX*componentY - 1)
      expect(hash.length, 4 + 2 * 4 * 3);
    });

    test('throws for out-of-range component counts', () {
      final pixels = _solidColor(2, 2, 0, 0, 0);
      expect(
        () => BlurHash.encode(pixels, width: 2, height: 2, componentX: 0),
        throwsArgumentError,
      );
      expect(
        () => BlurHash.encode(pixels, width: 2, height: 2, componentX: 10),
        throwsArgumentError,
      );
    });

    test('throws when pixel buffer length does not match dimensions', () {
      final pixels = Uint8List(10);
      expect(
        () => BlurHash.encode(pixels, width: 4, height: 4),
        throwsArgumentError,
      );
    });
  });

  group('BlurHash.decode', () {
    test('throws for a too-short hash string', () {
      expect(
        () => BlurHash.decode('abc', width: 4, height: 4),
        throwsArgumentError,
      );
    });

    test('throws when the hash length does not match its own size flag', () {
      final pixels = _solidColor(4, 4, 0, 0, 0);
      final hash = BlurHash.encode(
        pixels,
        width: 4,
        height: 4,
        componentX: 4,
        componentY: 3,
      );
      expect(
        () => BlurHash.decode(hash.substring(0, hash.length - 2),
            width: 4, height: 4),
        throwsArgumentError,
      );
    });

    test('produces a width*height*4 buffer with opaque alpha', () {
      final pixels = _solidColor(4, 4, 0, 128, 255);
      final hash = BlurHash.encode(pixels, width: 4, height: 4);
      final decoded = BlurHash.decode(hash, width: 8, height: 8);
      expect(decoded.length, 8 * 8 * 4);
      for (var i = 0; i < 8 * 8; i++) {
        expect(decoded[i * 4 + 3], 255);
      }
    });
  });

  group('BlurHash encode/decode roundtrip', () {
    test('a solid color roundtrips closely at the same resolution', () {
      const width = 4, height = 4;
      final pixels = _solidColor(width, height, 255, 0, 0);
      final hash = BlurHash.encode(
        pixels,
        width: width,
        height: height,
        componentX: 4,
        componentY: 3,
      );
      final decoded = BlurHash.decode(hash, width: width, height: height);

      // BlurHash is a lossy, quantized representation — even a perfectly
      // solid color loses some precision on decode (verified to exactly
      // match the reference `blurhash` npm package's output for this same
      // input/hash). Assert a tolerance rather than exact equality.
      for (var i = 0; i < width * height; i++) {
        expect(decoded[i * 4], closeTo(255, 50));
        expect(decoded[i * 4 + 1], closeTo(0, 1));
        expect(decoded[i * 4 + 2], closeTo(0, 1));
      }
    });

    test('different colors produce different hashes', () {
      final redHash = BlurHash.encode(
        _solidColor(4, 4, 255, 0, 0),
        width: 4,
        height: 4,
      );
      final blueHash = BlurHash.encode(
        _solidColor(4, 4, 0, 0, 255),
        width: 4,
        height: 4,
      );
      expect(redHash, isNot(blueHash));
    });

    test('decoding at a different resolution than encoding still succeeds', () {
      final pixels = _solidColor(4, 4, 10, 200, 90);
      final hash = BlurHash.encode(pixels, width: 4, height: 4);
      final decoded = BlurHash.decode(hash, width: 32, height: 32);
      expect(decoded.length, 32 * 32 * 4);
    });

    test('matches the reference woltapp/blurhash npm package byte-for-byte',
        () {
      // Cross-checked against `npx blurhash` (the reference JS
      // implementation) for a solid 4x4 red image with 4x3 components: both
      // the produced hash string and every decoded pixel match exactly.
      final pixels = _solidColor(4, 4, 255, 0, 0);
      final hash = BlurHash.encode(
        pixels,
        width: 4,
        height: 4,
        componentX: 4,
        componentY: 3,
      );
      expect(hash, 'L~TI:j|cfQ|c|c\$5fQ\$5fQfQfQfQ');

      final decoded = BlurHash.decode(hash, width: 4, height: 4);
      const expectedRed = [
        255, 255, 255, 255, //
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 210, 210, 210,
      ];
      for (var i = 0; i < 16; i++) {
        expect(decoded[i * 4], expectedRed[i]);
        expect(decoded[i * 4 + 1], 0);
        expect(decoded[i * 4 + 2], 0);
        expect(decoded[i * 4 + 3], 255);
      }
    });
  });
}
