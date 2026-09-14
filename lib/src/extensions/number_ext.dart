import 'package:intl/intl.dart';

/// Extension methods on [num] to format numbers and currency in Indonesian.
extension IndonesianCurrency on num {
  /// Formats as Indonesian Rupiah. Example: `60000` → `Rp 60.000`.
  String toRupiah({bool withDecimal = false}) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: withDecimal ? 2 : 0,
    );
    return fmt.format(this);
  }

  /// Formats with `K` suffix for thousands. Example: `6500` → `6,5K`.
  String toK() {
    if (this >= 1000) {
      final value = this / 1000;
      final fmt = NumberFormat('0.##', 'id_ID');
      return '${fmt.format(value)}K';
    }
    return toString();
  }

  /// Short informal Rupiah format. Example: `1500000` → `Rp 1,5jt`,
  /// `50000` → `Rp 50rb`.
  ///
  /// All branches use Indonesian (`id_ID`) locale formatting consistently
  /// (comma `,` as the decimal separator, matching the `< 1000` fallback's
  /// thousand grouping), so a `.` never appears with two different meanings
  /// (decimal point vs. thousands separator) across the same output family.
  String toShortRupiah() {
    final fmt = NumberFormat('0.#', 'id_ID');
    if (this >= 1000000) {
      final value = this / 1000000;
      return 'Rp ${fmt.format(value)}jt';
    } else if (this >= 1000) {
      final value = this / 1000;
      return 'Rp ${fmt.format(value)}rb';
    }
    return 'Rp ${NumberFormat.decimalPattern('id_ID').format(this)}';
  }

  /// Formats with a custom currency symbol.
  String toCurrency({String symbol = 'Rp', bool withDecimal = true}) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '$symbol ',
      decimalDigits: withDecimal ? 2 : 0,
    );
    return fmt.format(this);
  }

  /// Formats with thousand separators. Defaults to Indonesian locale (`id_ID`).
  ///
  /// Example (id_ID): `1000` → `1.000`
  String toGroupedDigits({String locale = 'id_ID'}) {
    final fmt = NumberFormat.decimalPattern(locale);
    return fmt.format(this);
  }
}
