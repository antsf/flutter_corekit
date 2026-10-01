import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all valid normalized phone lengths preserve every digit when formatted',
      () {
    for (var localLength = 9; localLength <= 12; localLength++) {
      final local = '8${'1' * (localLength - 1)}';
      for (final number in ['0$local', '62$local', '+62$local', local]) {
        expect(number.isValidIndonesianPhone, isTrue);
        for (final hyphen in [false, true]) {
          final formatted = number.formatPhoneNumber(useHyphen: hyphen);
          expect(formatted?.replaceAll(RegExp(r'\D'), ''), '62$local');
        }
      }
    }
    expect('08123456789'.formatPhoneNumber(), '62 812 3456 789');
    expect(''.formatPhoneNumber(), isNull);
    expect('123'.formatPhoneNumber(), isNull);
  });
}
