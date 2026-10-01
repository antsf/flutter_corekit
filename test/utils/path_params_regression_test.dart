import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder names are matched in full irrespective of map order', () {
    expect(PathUtils.replaceParams('/users/:id2/{id}', {'id': 7, 'id2': 9}),
        '/users/9/7');
    expect(PathUtils.replaceParams('/users/:id2/{id}', {'id2': 9, 'id': 7}),
        '/users/9/7');
    expect(() => PathUtils.replaceParams('/users/:id2', {'id': 7}),
        throwsArgumentError);
  });

  test('standalone dot-segment parameters are rejected for route integrity',
      () {
    for (final value in ['.', '..']) {
      expect(() => PathUtils.replaceParams('/users/:id/detail', {'id': value}),
          throwsArgumentError);
    }
  });

  test(
      'parameters cannot inject separators, fragments, or further placeholders',
      () {
    const raw = 'a/b?x=1#anchor:{id}';
    final path = PathUtils.replaceParams('/users/:id/detail', {'id': raw});
    expect(path, '/users/${Uri.encodeComponent(raw)}/detail');
    final uri = Uri.parse('https://api.test').resolve(path);
    expect(uri.pathSegments, ['users', raw, 'detail']);
    expect(uri.hasQuery, isFalse);
    expect(uri.hasFragment, isFalse);
  });
}
