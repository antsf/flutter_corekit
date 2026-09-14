import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// --- EXTENSIONS UNDER TEST ---

// /// Extension methods on [num] to format numbers and currency in Indonesian.
// extension IndonesianCurrency on num {
//   /// Formats the number as Indonesian Rupiah (e.g., Rp60.000,00).
//   ///
//   /// Set `withDecimal` to `false` to drop the decimal places.
//   String toRupiah({bool withDecimal = false}) {
//     // Note: The 'Rp ' symbol from the NumberFormat often includes a non-breaking space,
//     // which may appear as a regular space in some environments.
//     final fmt = NumberFormat.currency(
//       locale: 'id_ID',
//       symbol: 'Rp ',
//       decimalDigits: withDecimal ? 2 : 0,
//     );
//     return fmt.format(this);
//   }

//   /// Formats the number with a 'K' suffix for thousands (e.g., 6,5K, 100K).
//   ///
//   /// This is useful for displaying large numbers in a concise format.
//   String toK() {
//     if (this >= 1000) {
//       final value = this / 1000;
//       // Using '0.##' for up to two decimal places, and 'id_ID' for comma decimal separator.
//       final fmt = NumberFormat('0.##', 'id_ID');
//       return '${fmt.format(value)}K';
//     }
//     return toString();
//   }

//   /// Formats the number into a short, informal Rupiah format (e.g., Rp 60rb).
//   ///
//   /// This is commonly used in user interfaces for better readability.
//   String toShortRupiah() {
//     if (this >= 1000000) {
//       final value = this / 1000000;
//       return 'Rp ${NumberFormat('0.#').format(value)}jt';
//     } else if (this >= 1000) {
//       final value = this / 1000;
//       return 'Rp ${NumberFormat('0.#').format(value)}rb';
//     }
//     // Fallback for numbers < 1000
//     return 'Rp ${NumberFormat.decimalPattern('id_ID').format(this)}';
//   }

//   /// A more general currency formatter that can handle various symbols.
//   ///
//   /// [symbol]: The currency symbol to use (e.g., '€', '$'). Defaults to 'Rp'.
//   /// [withDecimal]: Whether to include decimal places.
//   String toCurrency({String symbol = 'Rp', bool withDecimal = true}) {
//     final fmt = NumberFormat.currency(
//       locale: 'id_ID',
//       // Note: The extra space after $symbol is part of the NumberFormat standard
//       // for most locales when the symbol is custom or not the locale's default.
//       symbol: '$symbol ',
//       decimalDigits: withDecimal ? 2 : 0,
//     );
//     return fmt.format(this);
//   }

//   /// Formats the number with thousand separators based on a specified locale.
//   ///
//   /// For Indonesian (`id_ID`), this results in a period as the separator (e.g., "1.000").
//   /// For US English (`en_US`), this results in a comma as the separator (e.g., "1,000").
//   String toGroupedDigits({String locale = 'id_ID'}) {
//     final fmt = NumberFormat.decimalPattern(locale);
//     return fmt.format(this);
//   }
// }

// --- UNIT TESTS ---

void main() {
  // Ensure locale data is available for 'id_ID' and 'en_US'
  Intl.defaultLocale =
      'en_US'; // Set a default to ensure predictable results in tests
  Intl.systemLocale = 'en_US';

  // Initialize 'id_ID' locale data if running outside a full Flutter environment
  Intl.withLocale('id_ID', () {});

  group('IndonesianCurrency Extension Tests', () {
    // Helper function to safely format by removing potential non-breaking spaces
    String cleanFormat(String input) {
      return input.replaceAll(' ',
          ' '); // Replace non-breaking space (U+00A0) with standard space (U+0020)
    }

    group('toRupiah', () {
      test('formats number correctly without decimals (default)', () {
        const value = 1250000;
        const expected = 'Rp 1.250.000';
        expect(cleanFormat(value.toRupiah()), expected);
      });

      test('formats number correctly with decimals (withDecimal: true)', () {
        const value = 12500.75;
        // id_ID uses comma as decimal separator
        const expected = 'Rp 12.500,75';
        expect(cleanFormat(value.toRupiah(withDecimal: true)), expected);
      });

      test('formats small number correctly', () {
        const value = 500;
        const expected = 'Rp 500';
        expect(cleanFormat(value.toRupiah()), expected);
      });
    });

    group('toK', () {
      test('formats exact thousand with no decimal', () {
        const value = 1000;
        expect(value.toK(), '1K');
      });

      test('formats number over thousand with one decimal place', () {
        const value = 1500;
        expect(value.toK(), '1,5K'); // id_ID uses comma
      });

      test('formats large number with no decimal needed', () {
        const value = 123000;
        expect(value.toK(), '123K');
      });

      // test('formats large number with multiple decimals', () {
      //   const value = 123456789;
      //   expect(value.toK(),
      //       '123.456,79K'); // Rounded to 2 decimals, id_ID thousand separator
      // });

      test('returns original number string if less than 1000', () {
        const value = 999;
        expect(value.toK(), '999');
      });
    });

    group('toShortRupiah', () {
      test('formats number in millions (>= 1,000,000) with "jt" suffix', () {
        const value = 2500000;
        expect(value.toShortRupiah(), 'Rp 2,5jt');
      });

      test('formats number in thousands (>= 1,000) with "rb" suffix', () {
        const value = 50000;
        expect(value.toShortRupiah(), 'Rp 50rb');
      });

      test('formats number just under one million', () {
        const value = 999000;
        expect(value.toShortRupiah(), 'Rp 999rb');
      });

      test('formats number just over a thousand', () {
        const value = 1050;
        expect(value.toShortRupiah(), 'Rp 1,1rb');
      });

      test('formats number less than 1000 (full format)', () {
        const value = 999;
        expect(value.toShortRupiah(), 'Rp 999');
      });
    });

    group('toCurrency', () {
      test('formats with default symbol and decimals', () {
        const value = 7500.20;
        const expected = 'Rp 7.500,20';
        expect(cleanFormat(value.toCurrency()), expected);
      });

      test('formats with custom symbol and no decimals', () {
        const value = 100000;
        const expected = '€ 100.000';
        expect(cleanFormat(value.toCurrency(symbol: '€', withDecimal: false)),
            expected);
      });
    });

    group('toGroupedDigits', () {
      test('formats with default id_ID locale (dot thousand separator)', () {
        const value = 1234567;
        expect(value.toGroupedDigits(), '1.234.567');
      });

      test('formats with en_US locale (comma thousand separator)', () {
        const value = 1234567;
        expect(value.toGroupedDigits(locale: 'en_US'), '1,234,567');
      });

      test('formats decimal number with id_ID locale', () {
        const value = 1234.56;
        expect(value.toGroupedDigits(locale: 'id_ID'), '1.234,56');
      });
    });
  });
}
