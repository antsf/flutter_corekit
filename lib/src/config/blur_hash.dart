import 'dart:math' as math;
import 'dart:typed_data';

/// Pure-Dart implementation of the [BlurHash](https://blurhash.io) algorithm
/// — encodes an image's RGBA pixel buffer into a short placeholder string,
/// and decodes that string back into a pixel buffer for painting.
///
/// This has no image-decoding dependency: callers are responsible for
/// getting raw RGBA bytes into [BlurHash.encode] (e.g. via `dart:ui`'s
/// `Image.toByteData(format: ImageByteFormat.rawRgba)` or the `image`
/// package), and for turning [BlurHash.decode]'s output bytes into a
/// paintable image (e.g. `decodeImageFromPixels`).
///
/// Implements the same algorithm as the reference implementations at
/// https://github.com/woltapp/blurhash, verified against its published test
/// vectors (see `test/config/blur_hash_test.dart`).
class BlurHash {
  BlurHash._();

  static const _base83Chars =
      r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

  /// Encodes RGBA [pixels] (`width * height * 4` bytes, row-major, no
  /// padding) into a BlurHash string.
  ///
  /// [componentX] and [componentY] (1–9 each) control how many DCT
  /// components are kept on each axis — more components capture more detail
  /// at the cost of a longer hash string. `4x3` is a common default.
  static String encode(
    Uint8List pixels, {
    required int width,
    required int height,
    int componentX = 4,
    int componentY = 3,
  }) {
    if (componentX < 1 || componentX > 9 || componentY < 1 || componentY > 9) {
      throw ArgumentError('componentX/componentY must be within 1..9');
    }
    if (pixels.length != width * height * 4) {
      throw ArgumentError(
        'pixels length (${pixels.length}) does not match '
        'width * height * 4 (${width * height * 4})',
      );
    }

    final factors = <List<double>>[];
    for (var y = 0; y < componentY; y++) {
      for (var x = 0; x < componentX; x++) {
        factors.add(_multiplyBasisFunction(pixels, width, height, x, y));
      }
    }

    final dc = factors[0];
    final ac = factors.sublist(1);

    final buffer = StringBuffer();

    final sizeFlag = (componentX - 1) + (componentY - 1) * 9;
    buffer.write(_encode83(sizeFlag, 1));

    double maximumValue;
    if (ac.isNotEmpty) {
      var actualMaximumValue = 0.0;
      for (final f in ac) {
        for (final v in f) {
          actualMaximumValue = math.max(actualMaximumValue, v.abs());
        }
      }
      final quantisedMaximumValue =
          math.max(0, math.min(82, (actualMaximumValue * 166 - 0.5).floor()));
      maximumValue = (quantisedMaximumValue + 1) / 166;
      buffer.write(_encode83(quantisedMaximumValue, 1));
    } else {
      maximumValue = 1;
      buffer.write(_encode83(0, 1));
    }

    buffer.write(
      _encode83(_encodeDC(dc[0], dc[1], dc[2]), 4),
    );

    for (final f in ac) {
      buffer.write(_encode83(_encodeAC(f[0], f[1], f[2], maximumValue), 2));
    }

    return buffer.toString();
  }

  /// Decodes a BlurHash [hash] into an RGBA pixel buffer of
  /// `width * height * 4` bytes, at the given [width]/[height].
  ///
  /// [punch] (>= 1) exaggerates contrast in the decoded gradient — values
  /// above 1 produce a more saturated/contrasty placeholder.
  static Uint8List decode(
    String hash, {
    required int width,
    required int height,
    double punch = 1,
  }) {
    if (hash.length < 6) {
      throw ArgumentError('BlurHash string must be at least 6 characters');
    }

    final sizeFlag = _decode83(hash, 0, 1);
    final componentX = (sizeFlag % 9) + 1;
    final componentY = (sizeFlag ~/ 9) + 1;

    final expectedLength = 4 + 2 * componentX * componentY;
    if (hash.length != expectedLength) {
      throw ArgumentError(
        'BlurHash length mismatch: expected $expectedLength characters for '
        '$componentX x $componentY components, got ${hash.length}',
      );
    }

    final quantisedMaximumValue = _decode83(hash, 1, 1);
    final maximumValue = (quantisedMaximumValue + 1) / 166;

    final colors = List<List<double>>.filled(componentX * componentY, const [
      0,
      0,
      0,
    ]);
    colors[0] = _decodeDC(_decode83(hash, 2, 4));
    for (var i = 1; i < componentX * componentY; i++) {
      colors[i] = _decodeAC(
        _decode83(hash, 4 + i * 2, 2),
        maximumValue * punch,
      );
    }

    final pixels = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var r = 0.0, g = 0.0, b = 0.0;
        for (var j = 0; j < componentY; j++) {
          for (var i = 0; i < componentX; i++) {
            final basis = math.cos(math.pi * x * i / width) *
                math.cos(math.pi * y * j / height);
            final color = colors[i + j * componentX];
            r += color[0] * basis;
            g += color[1] * basis;
            b += color[2] * basis;
          }
        }
        final index = (y * width + x) * 4;
        pixels[index] = _linearToSrgb(r);
        pixels[index + 1] = _linearToSrgb(g);
        pixels[index + 2] = _linearToSrgb(b);
        pixels[index + 3] = 255;
      }
    }
    return pixels;
  }

  static List<double> _multiplyBasisFunction(
    Uint8List pixels,
    int width,
    int height,
    int componentX,
    int componentY,
  ) {
    var r = 0.0, g = 0.0, b = 0.0;
    final normalisation = componentX == 0 && componentY == 0 ? 1.0 : 2.0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final basis = math.cos(math.pi * componentX * x / width) *
            math.cos(math.pi * componentY * y / height);
        final index = (y * width + x) * 4;
        r += basis * _srgbToLinear(pixels[index]);
        g += basis * _srgbToLinear(pixels[index + 1]);
        b += basis * _srgbToLinear(pixels[index + 2]);
      }
    }

    final scale = normalisation / (width * height);
    return [r * scale, g * scale, b * scale];
  }

  static double _srgbToLinear(int value) {
    final v = value / 255;
    if (v <= 0.04045) return v / 12.92;
    return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static int _linearToSrgb(double value) {
    final v = value.clamp(0, 1).toDouble();
    final srgb =
        v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
    return (srgb * 255 + 0.5).floor().clamp(0, 255);
  }

  static int _encodeDC(double r, double g, double b) {
    final roundedR = _linearToSrgb(r);
    final roundedG = _linearToSrgb(g);
    final roundedB = _linearToSrgb(b);
    return (roundedR << 16) + (roundedG << 8) + roundedB;
  }

  static List<double> _decodeDC(int value) {
    final r = value >> 16;
    final g = (value >> 8) & 255;
    final b = value & 255;
    return [_srgbToLinear(r), _srgbToLinear(g), _srgbToLinear(b)];
  }

  static double _signPow(double value, double exp) =>
      value.sign * math.pow(value.abs(), exp).toDouble();

  static int _encodeAC(double r, double g, double b, double maximumValue) {
    final quantR =
        (_signPow(r / maximumValue, 0.5) * 9 + 9.5).floor().clamp(0, 18);
    final quantG =
        (_signPow(g / maximumValue, 0.5) * 9 + 9.5).floor().clamp(0, 18);
    final quantB =
        (_signPow(b / maximumValue, 0.5) * 9 + 9.5).floor().clamp(0, 18);
    return quantR * 19 * 19 + quantG * 19 + quantB;
  }

  static List<double> _decodeAC(int value, double maximumValue) {
    final quantR = value ~/ (19 * 19);
    final quantG = (value ~/ 19) % 19;
    final quantB = value % 19;

    return [
      _signPow((quantR - 9) / 9, 2) * maximumValue,
      _signPow((quantG - 9) / 9, 2) * maximumValue,
      _signPow((quantB - 9) / 9, 2) * maximumValue,
    ];
  }

  static String _encode83(int value, int length) {
    final buffer = StringBuffer();
    for (var i = 1; i <= length; i++) {
      final digit = (value ~/ _intPow(83, length - i)) % 83;
      buffer.write(_base83Chars[digit]);
    }
    return buffer.toString();
  }

  static int _decode83(String string, int start, int length) {
    var value = 0;
    for (var i = start; i < start + length; i++) {
      final digit = _base83Chars.indexOf(string[i]);
      if (digit == -1) {
        throw ArgumentError('Invalid BlurHash character: "${string[i]}"');
      }
      value = value * 83 + digit;
    }
    return value;
  }

  static int _intPow(int base, int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
