import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailInput', () {
    test('pure field has no error regardless of value', () {
      expect(const EmailInput.pure('not-an-email').error, isNull);
    });

    test('empty value is required', () {
      expect(const EmailInput.dirty('').error, 'This field is required');
    });

    test('malformed value is invalid', () {
      expect(const EmailInput.dirty('not-an-email').error, isNotNull);
    });

    test('valid email has no error', () {
      expect(const EmailInput.dirty('user@example.com').error, isNull);
      expect(const EmailInput.dirty('user@example.com').isValid, isTrue);
    });
  });

  group('PasswordInput', () {
    test('empty value is required', () {
      expect(const PasswordInput.dirty('').error, 'This field is required');
    });

    test('too-short value is invalid', () {
      expect(const PasswordInput.dirty('abc').error, isNotNull);
    });

    test('within-range value has no error', () {
      expect(const PasswordInput.dirty('validpass123').error, isNull);
    });

    test('custom min/max length is respected', () {
      expect(
        const PasswordInput.dirty('12345678', minLength: 10).error,
        isNotNull,
      );
      expect(
        const PasswordInput.dirty('1234567890', minLength: 10).error,
        isNull,
      );
    });
  });

  group('UsernameInput', () {
    test('empty value is required', () {
      expect(const UsernameInput.dirty('').error, 'This field is required');
    });

    test('too-short value is invalid', () {
      expect(const UsernameInput.dirty('ab').error, isNotNull);
    });

    test('value with invalid characters is invalid', () {
      expect(const UsernameInput.dirty('user name!').error, isNotNull);
    });

    test('valid username has no error', () {
      expect(const UsernameInput.dirty('user_name.1').error, isNull);
    });
  });

  group('OtpInput', () {
    test('empty value is required', () {
      expect(const OtpInput.dirty('').error, isNotNull);
    });

    test('non-numeric value is invalid', () {
      expect(const OtpInput.dirty('12a456').error, isNotNull);
    });

    test('wrong length is invalid', () {
      expect(const OtpInput.dirty('123').error, isNotNull);
    });

    test('correct length numeric code has no error', () {
      expect(const OtpInput.dirty('123456').error, isNull);
    });

    test('custom length is respected', () {
      expect(const OtpInput.dirty('1234', length: 4).error, isNull);
      expect(const OtpInput.dirty('123456', length: 4).error, isNotNull);
    });
  });

  group('RequiredInput', () {
    test('empty value is required', () {
      expect(const RequiredInput.dirty('').error, isNotNull);
    });

    test('whitespace-only value is required', () {
      expect(const RequiredInput.dirty('   ').error, isNotNull);
    });

    test('non-empty value has no error', () {
      expect(const RequiredInput.dirty('anything').error, isNull);
    });
  });

  group('IndonesianPhoneInput', () {
    test('empty value is required', () {
      expect(const IndonesianPhoneInput.dirty('').error, isNotNull);
    });

    test('invalid phone number is invalid', () {
      expect(const IndonesianPhoneInput.dirty('123').error, isNotNull);
    });

    test('valid Indonesian phone number has no error', () {
      expect(
        const IndonesianPhoneInput.dirty('081234567890').error,
        isNull,
      );
    });
  });
}
