import 'dart:async';

import 'test_helpers.dart';

/// Runs once per test file before its `main()`. The package's spacing
/// extensions (`.spacingHeight`/`.spacingWidth`/`.padding`/etc., see
/// `ui_ext.dart`'s `NumExtension`) call into flutter_screenutil's `.w`/`.h`,
/// which throw `LateInitializationError` until `ScreenUtil` has been
/// configured at least once. Widget tests build their own `MaterialApp`
/// directly (no `ScreenUtilInit` ancestor), so without this they'd crash on
/// first layout. Individual test files may still call
/// `initScreenUtilForTests()` again (e.g. in a `setUp`) — it's idempotent.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  initScreenUtilForTests();
  return testMain();
}
