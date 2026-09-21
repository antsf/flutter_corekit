import 'package:flutter_corekit/flutter_corekit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UriExt', () {
    test('withScheme prepends https:// to a bare host', () {
      final uri = Uri.parse('example.com');
      expect(uri.withScheme.toString(), 'https://example.com');
    });

    test('withScheme leaves an https URI unchanged', () {
      final uri = Uri.parse('https://example.com');
      expect(uri.withScheme, uri);
    });

    test('withScheme leaves an http URI unchanged', () {
      final uri = Uri.parse('http://example.com');
      expect(uri.withScheme, uri);
    });

    test('withScheme leaves a non-http scheme (mailto) unchanged', () {
      final uri = Uri.parse('mailto:test@example.com');
      expect(uri.withScheme, uri);
    });

    test('withScheme preserves path and query on a bare host', () {
      final uri = Uri.parse('example.com/path?x=1');
      expect(uri.withScheme.toString(), 'https://example.com/path?x=1');
    });
  });
}
