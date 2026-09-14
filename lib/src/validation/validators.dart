import '../extensions/string_ext.dart';
import 'form_input.dart';

/// {@template email_input}
/// A [FormInput] for an email address. Empty or non-email-shaped values are
/// invalid.
/// {@endtemplate}
class EmailInput extends FormInput<String> {
  /// {@macro email_input}
  const EmailInput.pure([super.value = '']) : super.pure();

  /// {@macro email_input}
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'This field is required';
    if (!_emailRegex.hasMatch(value)) return 'Email is not valid';
    return null;
  }
}

/// {@template password_input}
/// A [FormInput] for a password. Invalid when empty or outside
/// `[minLength, maxLength]` characters (defaults: 6–120).
/// {@endtemplate}
class PasswordInput extends FormInput<String> {
  /// {@macro password_input}
  const PasswordInput.pure([super.value = ''])
      : minLength = 6,
        maxLength = 120,
        super.pure();

  /// {@macro password_input}
  const PasswordInput.dirty(
    super.value, {
    this.minLength = 6,
    this.maxLength = 120,
  }) : super.dirty();

  /// The minimum accepted password length.
  final int minLength;

  /// The maximum accepted password length.
  final int maxLength;

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'This field is required';
    if (value.length < minLength || value.length > maxLength) {
      return 'Password should be $minLength–$maxLength characters';
    }
    return null;
  }
}

/// {@template username_input}
/// A [FormInput] for a username: 3–16 characters, letters, digits, `.`, and
/// `_` only.
/// {@endtemplate}
class UsernameInput extends FormInput<String> {
  /// {@macro username_input}
  const UsernameInput.pure([super.value = '']) : super.pure();

  /// {@macro username_input}
  const UsernameInput.dirty([super.value = '']) : super.dirty();

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,16}$');

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'This field is required';
    if (!_usernameRegex.hasMatch(value)) {
      return 'Username must be 3–16 characters: letters, numbers, '
          'periods, and underscores only';
    }
    return null;
  }
}

/// {@template otp_input}
/// A [FormInput] for a numeric OTP/verification code of exactly [length]
/// digits (default 6).
/// {@endtemplate}
class OtpInput extends FormInput<String> {
  /// {@macro otp_input}
  const OtpInput.pure([super.value = ''])
      : length = 6,
        super.pure();

  /// {@macro otp_input}
  const OtpInput.dirty(super.value, {this.length = 6}) : super.dirty();

  /// The exact number of digits required.
  final int length;

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'OTP code is required';
    if (!RegExp(r'^[0-9]+$').hasMatch(value) || value.length != length) {
      return 'Enter the $length-digit code';
    }
    return null;
  }
}

/// {@template required_input}
/// A generic [FormInput] for any non-empty text field (names, addresses,
/// etc.) where the only rule is "must not be empty (after trimming)".
/// {@endtemplate}
class RequiredInput extends FormInput<String> {
  /// {@macro required_input}
  const RequiredInput.pure([super.value = '']) : super.pure();

  /// {@macro required_input}
  const RequiredInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.trim().isEmpty) return 'This field is required';
    return null;
  }
}

/// {@template indonesian_phone_input}
/// A [FormInput] for an Indonesian phone number, reusing
/// `String.isValidIndonesianPhone` so a field that validates here also
/// formats successfully via `String.formatPhoneNumber`.
/// {@endtemplate}
class IndonesianPhoneInput extends FormInput<String> {
  /// {@macro indonesian_phone_input}
  const IndonesianPhoneInput.pure([super.value = '']) : super.pure();

  /// {@macro indonesian_phone_input}
  const IndonesianPhoneInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.isEmpty) return 'This field is required';
    if (!value.isValidIndonesianPhone) return 'Phone number is not valid';
    return null;
  }
}
