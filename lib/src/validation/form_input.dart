/// Lightweight, dependency-free replacement for the `formz` package's
/// `FormzInput` pattern: a form field that carries its own value, whether
/// it's been touched ("dirty"), and validation logic.
///
/// Deliberately does **not** depend on `formz`/`equatable` — this package
/// stays dependency-light, and the pattern itself is small enough to own.
///
/// Subclass and implement [validator]:
///
/// ```dart
/// class Age extends FormInput<int> {
///   const Age.pure([super.value = 0]) : super.pure();
///   const Age.dirty([super.value = 0]) : super.dirty();
///
///   @override
///   String? validator(int value) => value >= 18 ? null : 'Must be 18+';
/// }
///
/// final age = Age.dirty(15);
/// age.isValid; // false
/// age.error;   // 'Must be 18+'
/// ```
abstract class FormInput<T> {
  /// Creates a "pure" (untouched) field — [error] is suppressed until the
  /// field becomes dirty, even if [value] wouldn't validate.
  const FormInput.pure(this.value) : isPure = true;

  /// Creates a "dirty" (touched) field — [error] reflects [validator]
  /// immediately.
  const FormInput.dirty(this.value) : isPure = false;

  /// The field's current value.
  final T value;

  /// Whether the field has not yet been edited by the user. A pure field's
  /// [error] is always `null`, regardless of [value].
  final bool isPure;

  /// Validates [value]. Return `null` when valid, otherwise a validation
  /// error — typically a user-facing message [String], but any type is
  /// allowed (e.g. an error enum) for callers that localize separately.
  Object? validator(T value);

  /// The current validation error, or `null` if [isPure] or [value] is
  /// valid.
  Object? get error => isPure ? null : validator(value);

  /// Whether [value] passes [validator], irrespective of [isPure]. Useful
  /// for gating a submit button even while individual fields are still
  /// pure.
  bool get isValid => validator(value) == null;

  /// Whether [value] fails [validator].
  bool get isNotValid => !isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormInput<T> &&
          other.runtimeType == runtimeType &&
          other.value == value &&
          other.isPure == isPure);

  @override
  int get hashCode => Object.hash(runtimeType, value, isPure);

  @override
  String toString() =>
      '$runtimeType(value: $value, isPure: $isPure, error: $error)';
}

/// Aggregates multiple [FormInput]s to answer "is the whole form valid?"
/// without needing every field to be dirty.
///
/// ```dart
/// final isValid = FormValidation([email, password]).isValid;
/// ```
class FormValidation {
  /// Creates a [FormValidation] over the given [inputs].
  const FormValidation(this.inputs);

  /// The fields being validated together.
  final List<FormInput<dynamic>> inputs;

  /// Whether every input in [inputs] is valid (via [FormInput.isValid],
  /// ignoring [FormInput.isPure]).
  bool get isValid => inputs.every((input) => input.isValid);

  /// Whether at least one input in [inputs] is invalid.
  bool get isNotValid => !isValid;
}
