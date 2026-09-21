/// Extension methods on [Uri] for handling loosely-formed user input.
library;

/// Extension methods on [Uri] for handling loosely-formed user input.
extension UriExt on Uri {
  /// Returns this [Uri] unchanged if it already has a scheme (`http`,
  /// `https`, `mailto`, etc.), otherwise re-parses it with `https://`
  /// prepended.
  ///
  /// Useful for user-entered URLs (e.g. a website field in a profile form)
  /// where people commonly type `example.com` instead of
  /// `https://example.com` — passing the bare string to an [Uri]-consuming
  /// API (like `launchUrl`) would otherwise fail or be misinterpreted as a
  /// relative path.
  ///
  /// Example:
  /// ```dart
  /// Uri.parse('example.com').withScheme; // https://example.com
  /// Uri.parse('https://example.com').withScheme; // unchanged
  /// ```
  Uri get withScheme => hasScheme ? this : Uri.parse('https://$this');
}
