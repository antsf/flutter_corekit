import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Age extends FormInput<int> {
  const _Age.pure([super.value = 0]) : super.pure();
  const _Age.dirty([super.value = 0]) : super.dirty();

  @override
  String? validator(int value) => value >= 18 ? null : 'Must be 18+';
}

void main() {
  group('FormInput', () {
    test('a pure field has no error even if invalid', () {
      const age = _Age.pure(10);
      expect(age.isPure, isTrue);
      expect(age.error, isNull);
      // isValid ignores purity — the underlying value is still invalid.
      expect(age.isValid, isFalse);
    });

    test('a dirty field surfaces its validation error', () {
      const age = _Age.dirty(10);
      expect(age.isPure, isFalse);
      expect(age.error, 'Must be 18+');
      expect(age.isValid, isFalse);
      expect(age.isNotValid, isTrue);
    });

    test('a dirty field with a valid value has no error', () {
      const age = _Age.dirty(21);
      expect(age.error, isNull);
      expect(age.isValid, isTrue);
      expect(age.isNotValid, isFalse);
    });

    test('equality is based on runtimeType, value, and isPure', () {
      expect(const _Age.dirty(21), const _Age.dirty(21));
      expect(const _Age.dirty(21) == const _Age.pure(21), isFalse);
      expect(const _Age.dirty(21) == const _Age.dirty(20), isFalse);
    });

    test('hashCode is consistent with equality', () {
      expect(
        const _Age.dirty(21).hashCode,
        const _Age.dirty(21).hashCode,
      );
    });

    test('toString includes value, purity, and error', () {
      const age = _Age.dirty(10);
      expect(age.toString(), contains('10'));
      expect(age.toString(), contains('Must be 18+'));
    });
  });

  group('FormValidation', () {
    test('isValid is true only when every input is valid', () {
      final valid = FormValidation([
        const _Age.dirty(21),
        const _Age.dirty(30),
      ]);
      expect(valid.isValid, isTrue);
      expect(valid.isNotValid, isFalse);

      final invalid = FormValidation([
        const _Age.dirty(21),
        const _Age.dirty(10),
      ]);
      expect(invalid.isValid, isFalse);
      expect(invalid.isNotValid, isTrue);
    });

    test('isValid ignores purity, only checks the underlying value', () {
      final result = FormValidation([const _Age.pure(10)]);
      expect(result.isValid, isFalse);
    });

    test('an empty list of inputs is vacuously valid', () {
      expect(const FormValidation([]).isValid, isTrue);
    });
  });
}
