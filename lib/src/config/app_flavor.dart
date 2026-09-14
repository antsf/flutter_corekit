/// The build/runtime environment an app is running in.
///
/// Use with [AppFlavor] to resolve per-flavor configuration values (base
/// URLs, API keys, feature flags) without scattering `if (kDebugMode)` or
/// hand-rolled `--dart-define` lookups across the codebase.
enum AppFlavorEnv {
  /// Local/dev builds — typically pointed at a dev or staging backend.
  development,

  /// Internal/QA staging builds.
  staging,

  /// Production builds, released to end users.
  production;

  /// Whether this is [development].
  bool get isDevelopment => this == AppFlavorEnv.development;

  /// Whether this is [staging].
  bool get isStaging => this == AppFlavorEnv.staging;

  /// Whether this is [production].
  bool get isProduction => this == AppFlavorEnv.production;
}

/// {@template app_flavor}
/// Resolves per-environment configuration values by [AppFlavorEnv], so app
/// code asks "what's my base URL" once, in one place, instead of scattering
/// environment checks everywhere.
///
/// Typically created once at startup (e.g. via three flavor-specific
/// `main_development.dart` / `main_staging.dart` / `main_production.dart`
/// entry points) and passed through the app, e.g. via a `Provider` or a
/// static field.
///
/// ```dart
/// // main_production.dart
/// void main() {
///   final flavor = AppFlavor(
///     env: AppFlavorEnv.production,
///     values: {
///       'baseUrl': 'https://api.example.com',
///       'sentryDsn': 'https://...',
///     },
///   );
///   runApp(MyApp(flavor: flavor));
/// }
///
/// // Usage anywhere the flavor is available:
/// final baseUrl = flavor.require<String>('baseUrl');
/// ```
/// {@endtemplate}
class AppFlavor {
  /// {@macro app_flavor}
  const AppFlavor({
    required this.env,
    this.values = const {},
  });

  /// Which environment this flavor represents.
  final AppFlavorEnv env;

  /// Arbitrary per-flavor configuration values, keyed by name. Values are
  /// typically primitives (`String`, `bool`, `int`) set up once at each
  /// flavor's entry point.
  final Map<String, Object?> values;

  /// Whether this is [AppFlavorEnv.development].
  bool get isDevelopment => env.isDevelopment;

  /// Whether this is [AppFlavorEnv.staging].
  bool get isStaging => env.isStaging;

  /// Whether this is [AppFlavorEnv.production].
  bool get isProduction => env.isProduction;

  /// Returns the value for [key], or `null` if absent.
  ///
  /// Throws a [TypeError] if the stored value isn't a [T] (fails fast on a
  /// misconfigured flavor rather than silently returning the wrong type).
  T? get<T>(String key) => values[key] as T?;

  /// Returns the value for [key], throwing a [StateError] if it's absent.
  ///
  /// Prefer this for values every flavor must supply (e.g. `baseUrl`) so a
  /// missing entry fails loudly at the call site instead of surfacing as a
  /// confusing null-check error deeper in the app.
  T require<T>(String key) {
    final value = values[key];
    if (value == null) {
      throw StateError(
        'AppFlavor($env): missing required config value "$key"',
      );
    }
    return value as T;
  }

  @override
  String toString() => 'AppFlavor(env: $env, keys: ${values.keys.toList()})';
}
