import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('absent delete never inserts even with insertIfNotFound default true',
      () {
    final list = [1, 2];
    expect(
        identical(
            list.updateWith<int>(
                newItem: 3,
                isDelete: true,
                findItemCallback: (old, item) => old == item,
                onUpdate: (old, item) => fail('delete must not invoke update')),
            list),
        isTrue);
    expect(list, [1, 2]);
    list.updateWith<int>(
        newItem: 2,
        isDelete: true,
        findItemCallback: (old, item) => old == item,
        onUpdate: (old, item) => item);
    expect(list, [1]);
  });

  test('unmodifiable absent delete is a no-op without mutation failure', () {
    final list = List<int>.unmodifiable([1]);
    list.updateWith<int>(
        newItem: 3,
        isDelete: true,
        findItemCallback: (old, item) => old == item,
        onUpdate: (old, item) => item);
    expect(list, [1]);
  });
}
