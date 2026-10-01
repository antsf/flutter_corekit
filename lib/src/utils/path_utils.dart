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
  /// `/users/42`. Values containing separators are component-encoded.
  /// Standalone `.` and `..` are rejected to preserve route integrity under
  /// URI normalization. Placeholder names are matched in full, in one pass.
  ///
  /// Throws an [ArgumentError] if the resulting path still contains an
  /// unresolved `:key`/`{key}` placeholder, so a missing required param
  /// fails loudly instead of silently reaching the network layer.
  static String replaceParams(String path, Map<String, dynamic> params) {
    final placeholder = RegExp(r':([A-Za-z0-9_]+)|\{([A-Za-z0-9_]+)\}');
    return path.replaceAllMapped(placeholder, (match) {
      final key = match.group(1) ?? match.group(2)!;
      if (!params.containsKey(key)) {
        throw ArgumentError(
            'Unresolved path parameter "${match.group(0)}" — missing key.');
      }
      final value = params[key].toString();
      if (value == '.' || value == '..') {
        throw ArgumentError(
            'Dot-segment path parameter "$key" is not allowed.');
      }
      return Uri.encodeComponent(value);
    });
  }
}
