import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  const _Item(this.id, this.value);
  final int id;
  final String value;
}

void main() {
  group('UpdateListExt.updateWith', () {
    bool findById(_Item item, _Item newItem) => item.id == newItem.id;
    _Item replace(_Item item, _Item newItem) => newItem;

    test('returns the list unchanged when newItem is null', () {
      final list = [const _Item(1, 'a')];
      final result = list.updateWith<_Item>(
        newItem: null,
        findItemCallback: findById,
        onUpdate: replace,
      );
      expect(result, same(list));
      expect(result.single.value, 'a');
    });

    test('inserts at index 0 when no match is found', () {
      final list = [const _Item(1, 'a')];
      final result = list.updateWith<_Item>(
        newItem: const _Item(2, 'b'),
        findItemCallback: findById,
        onUpdate: replace,
      );
      expect(result.map((e) => e.id), [2, 1]);
    });

    test('does not insert when insertIfNotFound is false', () {
      final list = [const _Item(1, 'a')];
      final result = list.updateWith<_Item>(
        newItem: const _Item(2, 'b'),
        findItemCallback: findById,
        onUpdate: replace,
        insertIfNotFound: false,
      );
      expect(result.map((e) => e.id), [1]);
    });

    test('replaces the matched element via onUpdate', () {
      final list = [const _Item(1, 'a'), const _Item(2, 'b')];
      final result = list.updateWith<_Item>(
        newItem: const _Item(2, 'updated'),
        findItemCallback: findById,
        onUpdate: replace,
      );
      expect(result.map((e) => e.value), ['a', 'updated']);
    });

    test('removes the matched element when isDelete is true', () {
      final list = [const _Item(1, 'a'), const _Item(2, 'b')];
      final result = list.updateWith<_Item>(
        newItem: const _Item(2, 'ignored'),
        findItemCallback: findById,
        onUpdate: replace,
        isDelete: true,
      );
      expect(result.map((e) => e.id), [1]);
    });

    test('mutates and returns the same list instance', () {
      final list = [const _Item(1, 'a')];
      final result = list.updateWith<_Item>(
        newItem: const _Item(1, 'updated'),
        findItemCallback: findById,
        onUpdate: replace,
      );
      expect(identical(result, list), isTrue);
    });
  });
}
