import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('password equality includes min and max validation policies', () {
    const base = PasswordInput.dirty('abcdefgh', minLength: 8);
    const stricter = PasswordInput.dirty('abcdefgh', minLength: 10);
    const shorterMax =
        PasswordInput.dirty('abcdefgh', minLength: 8, maxLength: 7);
    expect(base.isValid, isTrue);
    expect(stricter.isValid, isFalse);
    expect(base, isNot(stricter));
    expect(base, isNot(shorterMax));
    expect({base, stricter, shorterMax}, hasLength(3));
    expect(base, const PasswordInput.dirty('abcdefgh', minLength: 8));
    expect(base.hashCode,
        const PasswordInput.dirty('abcdefgh', minLength: 8).hashCode);
  });

  test('OTP equality includes required length', () {
    const six = OtpInput.dirty('123456');
    const four = OtpInput.dirty('123456', length: 4);
    expect(six.isValid, isTrue);
    expect(four.isValid, isFalse);
    expect(six, isNot(four));
    expect({six, four}, hasLength(2));
    expect(six, const OtpInput.dirty('123456'));
  });
}
