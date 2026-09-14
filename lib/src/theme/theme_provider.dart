import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

/// Manages and persists light/dark theme selection and notifies listeners.
///
/// Theme mode is a non-sensitive UI preference, so it is stored in
/// `shared_preferences` (fast) rather than secure storage.
class ThemeProvider extends ChangeNotifier {
  static ThemeProvider? _instance;

  /// `shared_preferences` key used to persist the dark-mode flag.
  static const String themeModeKey = 'flutter_corekit.theme_mode';

  // Optional custom themes supplied via [configure].
  ThemeData? _customLightTheme;
  ThemeData? _customDarkTheme;

  ThemeData _currentTheme = AppTheme.defaultLightTheme;
  bool _isDarkMode = false;

  ThemeProvider._();

  static ThemeProvider get instance => _instance ??= ThemeProvider._();

  /// Configure the provider with custom light/dark themes.
  /// Call once before the app starts (e.g. in `main`).
  static void configure({
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    _instance ??= ThemeProvider._();
    _instance!._customLightTheme = lightTheme;
    _instance!._customDarkTheme = darkTheme;
    _instance!._updateTheme();
    _instance!.notifyListeners();
  }

  /// The currently active theme (custom if provided, otherwise the default).
  ThemeData get currentTheme => _currentTheme;

  /// Whether dark mode is currently active.
  bool get isDarkMode => _isDarkMode;

  /// Loads the saved theme mode from `shared_preferences`.
  ///
  /// If reading the stored preference fails for any reason (plugin not yet
  /// registered, platform exception, etc.), this falls back to light mode
  /// instead of throwing, so a storage hiccup never blocks app startup.
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(themeModeKey) ?? false;
    } catch (e, s) {
      debugPrint('ThemeProvider.loadThemeMode: failed to read preference, '
          'defaulting to light mode. $e\n$s');
      _isDarkMode = false;
    }
    _updateTheme();
    notifyListeners();
  }

  void _updateTheme() {
    _currentTheme = _isDarkMode
        ? (_customDarkTheme ?? AppTheme.defaultDarkTheme)
        : (_customLightTheme ?? AppTheme.defaultLightTheme);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeModeKey, _isDarkMode);
  }

  /// Toggles between light and dark, persisting the choice.
  ///
  /// The in-memory state and listeners are updated optimistically (so the UI
  /// reflects the change immediately). If persistence fails, the change is
  /// still applied for the current session, but listeners are notified again
  /// only if a caller wants to react to the failure — the [StateError] is
  /// rethrown after the optimistic update so state and UI never disagree
  /// with each other, and the caller can decide how to surface the failure.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _updateTheme();
    notifyListeners();
    try {
      await _save();
    } catch (e, s) {
      debugPrint('ThemeProvider.toggleTheme: failed to persist preference. '
          '$e\n$s');
      rethrow;
    }
  }

  /// Sets the theme mode explicitly, persisting the choice.
  ///
  /// Same optimistic-update-then-persist contract as [toggleTheme]: state
  /// and listeners update immediately, and a persistence failure is
  /// rethrown (after the in-memory state and UI are already consistent)
  /// rather than left silent.
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    _updateTheme();
    notifyListeners();
    try {
      await _save();
    } catch (e, s) {
      debugPrint('ThemeProvider.setDarkMode: failed to persist preference. '
          '$e\n$s');
      rethrow;
    }
  }

  /// Resets the singleton instance (for testing only).
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}
