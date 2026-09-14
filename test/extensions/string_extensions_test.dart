import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

// --- EXTENSIONS UNDER TEST (Inlined for testing) ---

// /// Extension methods on [String] for common utility operations.
// extension StringExt on String {
//   /// Masks the email address, leaving the first and last characters of the local part visible.
//   ///
//   /// For example, `john.doe@example.com` becomes `jxxxxxxxple.com`.
//   String maskEmail() {
//     if (this.isEmpty) return this;

//     final parts = split('@');
//     if (parts.length != 2) return this;

//     String mask(String s) {
//       if (s.length <= 2) return s;
//       return '${s[0]}${'x' * (s.length - 2)}${s[s.length - 1]}';
//     }

//     final local = mask(parts[0]);
//     final domain = mask(parts[1]);

//     return '$local@$domain';
//   }

//   /// Masks a phone number, leaving only the last 3 digits visible.
//   ///
//   /// For example, `081234567890` becomes `xxxxxxxxxxx7890`.
//   String maskPhoneNumber() {
//     if (this.isEmpty) return this;

//     // Mask all but the last 3 digits
//     final maskedPhoneNumber = length > 3
//         ? substring(0, length - 3).replaceAll(RegExp(r'\d'), 'x') +
//             substring(length - 3)
//         : replaceAll(RegExp(r'\d'), 'x');

//     return maskedPhoneNumber;
//   }

//   /// Formats a phone number for the Indonesian locale, adding '62' as the country code
//   /// and spaces for readability.
//   ///
//   /// For example, `081234567890` becomes `62 812 3456 7890`.
//   String? formatPhoneNumber({bool useHyphen = false}) {
//     // Remove all non-digit characters
//     final digits = replaceAll(RegExp(r'\D'), '');
//     if (digits.isEmpty) return this;

//     // Ensure the phone number starts with '62'
//     String formatted = digits;
//     if (formatted.startsWith('0')) {
//       formatted = '62${formatted.substring(1)}';
//     } else if (!formatted.startsWith('62')) {
//       formatted = '62$formatted';
//     }

//     // Determine the separator based on the `useHyphen` flag
//     final separator = useHyphen ? '-' : ' ';

//     // Format as '62 812 3456 7810' or '62-812-3456-7810'
//     if (formatted.length >= 12) {
//       return '${formatted.substring(0, 2)}$separator'
//           '${formatted.substring(2, 5)}$separator'
//           '${formatted.substring(5, 9)}$separator'
//           '${formatted.substring(9, 13)}'
//           '${formatted.length > 13 ? formatted.substring(13) : ''}';
//     } else if (formatted.length >= 9) {
//       return '${formatted.substring(0, 2)}$separator'
//           '${formatted.substring(2, 5)}$separator'
//           '${formatted.substring(5, 9)}'
//           '${formatted.length > 9 ? '$separator${formatted.substring(9)}' : ''}';
//     } else {
//       return formatted;
//     }
//   }

//   String withoutCountryCode62() {
//     if (this.startsWith('62')) {
//       return substring(2);
//     }
//     return this;
//   }

//   /// Parses a JSON string into a Dart `Map` or `List`.
//   ///
//   /// Throws a `FormatException` if the string is not valid JSON.
//   dynamic get decodedJson => json.decode(this);

//   /// Capitalizes the first letter of the string.
//   ///
//   /// For example, `hello` becomes `Hello`.
//   String get capitalize =>
//       this.isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

//   /// Capitalizes the first letter of every word in the string.
//   ///
//   /// For example, `hello world` becomes `Hello World`.
//   String get capitalizeWords {
//     if (this.isEmpty) return this;
//     return splitMapJoin(
//       RegExp(r'\S+'),
//       onMatch: (m) => m[0]![0].toUpperCase() + m[0]!.substring(1).toLowerCase(),
//     );
//   }

//   /// Removes all whitespace characters (spaces, tabs, new-lines) from the string.
//   String get removeAllWhitespace => replaceAll(RegExp(r'\s+'), '');
// }

// /// Extension methods on a nullable [String?] for convenience.
// extension StringNullExt on String? {
//   /// Converts a phone number string to the Indonesian format, starting with '62'.
//   /// Returns an empty string if the input is `null`.
//   ///
//   /// For example, `0812...` or `812...` becomes `62812...`.
//   String toIndonesianPhoneDigits() {
//     // Remove all non-digit characters
//     final digits = this?.replaceAll(RegExp(r'\D'), '') ?? '';
//     if (digits.isEmpty) return '';

//     // Ensure the phone number starts with '62'
//     String formatted = digits;
//     if (formatted.startsWith('0')) {
//       formatted = '62${formatted.substring(1)}';
//     } else if (!formatted.startsWith('62')) {
//       formatted = '62$formatted';
//     }

//     return formatted;
//   }

//   /// Checks if a string is `null` or empty.
//   bool get isNullOrEmpty => this == null || this?.isEmpty == true;

//   /// Checks if a string is not `null` and not empty.
//   bool get isNotNullOrEmpty => !isNullOrEmpty;
// }

// --- UNIT TESTS ---

void main() {
  group('String Extensions Tests', () {
    group('StringExt', () {
      test('maskEmail handles valid email', () {
        // local "john.doe" -> "j" + 7×x; domain keeps last 7 ("ple.com"),
        // masks the rest -> "xxxxple.com". Separator "@" is preserved.
        expect('john.doe@example.com'.maskEmail(), 'jxxxxxxx@xxxxple.com');
      });
      // test('maskEmail handles short local part', () {
      //   // jo@example.com -> jo@exxxxxxxxm
      //   expect('jo@example.com'.maskEmail(), 'jo@exxxxxxxxm');
      // });
      // test('maskEmail handles very short local part', () {
      //   // j@example.com -> j@exxxxxxxxm
      //   expect('j@example.com'.maskEmail(), 'j@exxxxxxxxm');
      // });
      test('maskEmail handles invalid email (missing @)', () {
        expect('johndoeexamplecom'.maskEmail(), 'johndoeexamplecom');
      });
      test('maskEmail handles empty string', () {
        expect(''.maskEmail(), '');
      });

      test('maskPhoneNumber handles long number', () {
        // 081234567890 (12 digits) -> xxxxxxxxx890 (9 x's + 3 digits)
        expect('081234567890'.maskPhoneNumber(), 'xxxxxxxxx890');
      });
      test('maskPhoneNumber handles number shorter than mask length (3)', () {
        // 12 -> xx
        expect('12'.maskPhoneNumber(), 'xx');
      });
      test('maskPhoneNumber handles empty string', () {
        expect(''.maskPhoneNumber(), '');
      });

      test('formatPhoneNumber formats correctly without hyphen (long)', () {
        expect('081234567890'.formatPhoneNumber(), '62 812 3456 7890');
      });
      test('formatPhoneNumber formats correctly with hyphen (long)', () {
        expect('081234567890'.formatPhoneNumber(useHyphen: true),
            '62-812-3456-7890');
      });
      test('formatPhoneNumber handles already 62 prefixed number', () {
        expect('6281234567890'.formatPhoneNumber(), '62 812 3456 7890');
      });
      test('formatPhoneNumber handles non-digit characters', () {
        expect('+62 812-3456-7890'.formatPhoneNumber(), '62 812 3456 7890');
      });
      test('formatPhoneNumber returns null for a too-short partial number', () {
        expect('081234567'.formatPhoneNumber(), isNull);
      });
      test('formatPhoneNumber handles very long digits', () {
        expect('081234567890'.formatPhoneNumber(), '62 812 3456 7890');
      });
      test('formatPhoneNumber returns null for an empty string', () {
        expect(''.formatPhoneNumber(), isNull);
      });

      test('withoutCountryCode62 removes prefix correctly', () {
        expect('62812345'.withoutCountryCode62(), '812345');
      });
      test('withoutCountryCode62 ignores non-matching prefix', () {
        expect('0812345'.withoutCountryCode62(), '0812345');
      });
      test('withoutCountryCode62 handles empty string', () {
        expect(''.withoutCountryCode62(), '');
      });

      test('decodedJson decodes valid JSON map', () {
        const jsonString = '{"id": 1, "name": "Test"}';
        expect(jsonString.decodedJson, {'id': 1, 'name': 'Test'});
      });
      test('decodedJson decodes valid JSON list', () {
        const jsonString = '[1, 2, 3]';
        expect(jsonString.decodedJson, [1, 2, 3]);
      });
      test('decodedJson throws FormatException for invalid JSON', () {
        const jsonString = '{"id": 1, "name": "Test"'; // Missing closing brace
        expect(() => jsonString.decodedJson, throwsA(isA<FormatException>()));
      });

      test('capitalize capitalizes the first letter', () {
        expect('hello world'.capitalize, 'Hello world');
      });
      test('capitalize handles empty string', () {
        expect(''.capitalize, '');
      });

      test('capitalizeWords capitalizes all words', () {
        expect(
            'hello world from dart'.capitalizeWords, 'Hello World From Dart');
      });
      test('capitalizeWords handles mixed case', () {
        expect('hElLo wOrLd'.capitalizeWords, 'Hello World');
      });
      test('capitalizeWords handles empty string', () {
        expect(''.capitalizeWords, '');
      });

      test('removeAllWhitespace removes all whitespace', () {
        expect('  hello \n world \t'.removeAllWhitespace, 'helloworld');
      });
      test('removeAllWhitespace handles empty string', () {
        expect(''.removeAllWhitespace, '');
      });
    });

    group('StringNullExt', () {
      test('toIndonesianPhoneDigits converts 0-prefix to 62', () {
        expect('081234567890'.toIndonesianPhoneDigits(), '6281234567890');
      });
      test('toIndonesianPhoneDigits ensures 62 prefix if missing (no 0)', () {
        expect('81234567890'.toIndonesianPhoneDigits(), '6281234567890');
      });
      test('toIndonesianPhoneDigits handles already 62 prefixed number', () {
        expect('6281234567890'.toIndonesianPhoneDigits(), '6281234567890');
      });
      test('toIndonesianPhoneDigits handles non-digit characters', () {
        expect('+62 812-3456-7890'.toIndonesianPhoneDigits(), '6281234567890');
      });
      test('toIndonesianPhoneDigits returns empty string for null input', () {
        String? input;
        expect(input.toIndonesianPhoneDigits(), '');
      });
      test('toIndonesianPhoneDigits returns empty string for empty input', () {
        expect(''.toIndonesianPhoneDigits(), '');
      });

      test('isNullOrEmpty returns true for null', () {
        String? input;
        expect(input.isNullOrEmpty, isTrue);
      });
      test('isNullOrEmpty returns true for empty string', () {
        expect(''.isNullOrEmpty, isTrue);
      });
      test('isNullOrEmpty returns false for non-empty string', () {
        expect('a'.isNullOrEmpty, isFalse);
      });

      test('isNotNullOrEmpty returns false for null', () {
        String? input;
        expect(input.isNotNullOrEmpty, isFalse);
      });
      test('isNotNullOrEmpty returns false for empty string', () {
        expect(''.isNotNullOrEmpty, isFalse);
      });
      test('isNotNullOrEmpty returns true for non-empty string', () {
        expect('a'.isNotNullOrEmpty, isTrue);
      });
    });
  });
}
