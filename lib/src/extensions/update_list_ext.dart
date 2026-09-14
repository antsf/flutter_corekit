import 'dart:developer' as dev;

/// Callback that decides whether [item] (an existing list element) matches
/// [newItem] (the incoming one), used by [UpdateListExt.updateWith] to find
/// which element to touch.
typedef FindItemCallback<T> = bool Function(T item, T newItem);

/// Callback that produces the replacement value when [UpdateListExt.updateWith]
/// finds a matching element: given the existing [item] and the incoming
/// [newItem], returns what should replace [item] in the list.
typedef UpdateCallback<T, E> = T Function(E item, T newItem);

/// Base type for exceptions thrown by [UpdateListExt.updateWith].
abstract class UpdateListException implements Exception {
  /// Creates an [UpdateListException] wrapping the underlying [error].
  const UpdateListException(this.error);

  /// The underlying error that was caught.
  final Object error;

  @override
  String toString() => 'UpdateListException: $error';
}

/// Thrown by [UpdateListExt.updateWith] when removing the matched element
/// fails.
class DeleteItemFailure extends UpdateListException {
  /// {@macro update_list_exception}
  const DeleteItemFailure(super.error);
}

/// Thrown by [UpdateListExt.updateWith] when replacing the matched element
/// fails.
class UpdateItemFailure extends UpdateListException {
  /// {@macro update_list_exception}
  const UpdateItemFailure(super.error);
}

/// Thrown by [UpdateListExt.updateWith] when inserting a non-matched item
/// fails.
class InsertItemFailure extends UpdateListException {
  /// {@macro update_list_exception}
  const InsertItemFailure(super.error);
}

/// Extension on [List] for update-or-insert-or-delete list mutation, useful
/// for hand-rolled state management over a `List<Model>` (e.g. applying a
/// realtime update/delete event to an in-memory list without rebuilding it
/// from scratch).
///
/// Ported from the pattern used in
/// https://github.com/itsezlife/flutter-instagram-offline-first-clone
/// (`packages/shared/lib/src/config/utilities/extensions/update_list_extension.dart`).
extension UpdateListExt<T> on List<T> {
  /// Updates this list in place and returns it.
  ///
  /// - If [newItem] is `null`, the list is returned unchanged.
  /// - If an element matching [newItem] is found (via [findItemCallback]):
  ///   - and [isDelete] is `true`, that element is removed;
  ///   - otherwise, it's replaced with the result of
  ///     `onUpdate(existingElement, newItem)`.
  /// - If no match is found and [insertIfNotFound] is `true` (the default),
  ///   [newItem] is inserted at index 0.
  ///
  /// Throws [DeleteItemFailure], [UpdateItemFailure], or [InsertItemFailure]
  /// if the underlying list mutation throws (e.g. an unmodifiable list).
  List<T> updateWith<E extends T>({
    required T? newItem,
    required FindItemCallback<T> findItemCallback,
    required UpdateCallback<T, E> onUpdate,
    bool isDelete = false,
    bool insertIfNotFound = true,
  }) {
    if (newItem == null) {
      dev.log(
        'updateWith: no newItem provided, returning list unchanged.',
      );
      return this;
    }

    final index = indexWhere((item) => findItemCallback(item, newItem));

    if (index == -1) {
      if (!insertIfNotFound) {
        dev.log('updateWith: no match found, insertIfNotFound is false.');
        return this;
      }
      try {
        insert(0, newItem);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(InsertItemFailure(error), stackTrace);
      }
      return this;
    }

    if (isDelete) {
      try {
        removeAt(index);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(DeleteItemFailure(error), stackTrace);
      }
    } else {
      try {
        this[index] = onUpdate(this[index] as E, newItem);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(UpdateItemFailure(error), stackTrace);
      }
    }
    return this;
  }
}
