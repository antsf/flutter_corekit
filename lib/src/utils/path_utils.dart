/// Path utility methods for building URLs and replacing parameters.
class PathUtils {
  /// Joins a base URL and a path, normalizing exactly one `/` between them.
  ///
  /// Example: `buildUrl('https://api.example.com/', '/users')` →
  /// `https://api.example.com/users` (no double slash, no missing slash).
  static String buildUrl(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  /// Replaces `:key` and `{key}` placeholders in [path] with the
  /// corresponding value from [params], URL-encoding each value so it
  /// cannot inject extra path segments, query strings, or fragments.
  ///
  /// Example: `replaceParams('/users/:id', {'id': '42'})` →
  /// `/users/42`. A value like `'../admin'` is percent-encoded rather than
  /// substituted verbatim, so it cannot escape the intended path segment.
  ///
  /// Throws an [ArgumentError] if the resulting path still contains an
  /// unresolved `:key`/`{key}` placeholder, so a missing required param
  /// fails loudly instead of silently reaching the network layer.
  static String replaceParams(String path, Map<String, dynamic> params) {
    var result = path;
    params.forEach((key, value) {
      final encoded = Uri.encodeComponent(value.toString());
      result = result.replaceAll(':$key', encoded);
      result = result.replaceAll('{$key}', encoded);
    });

    final unresolved = RegExp(r':[A-Za-z0-9_]+|\{[A-Za-z0-9_]+\}');
    final match = unresolved.firstMatch(result);
    if (match != null) {
      throw ArgumentError(
        'Unresolved path parameter "${match.group(0)}" in "$path" — '
        'missing key in params map.',
      );
    }

    return result;
  }
}
