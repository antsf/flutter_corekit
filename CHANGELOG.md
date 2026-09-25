# Changelog

All notable changes to this project will be documented in this file.

---

## 3.1.0 — 2026-09-25

### Added
- `ColorHexExt`/`ColorToHexExt` — hex string ↔ `Color` conversion.
- `UriExt.withScheme` — prepends `https://` to a bare-host URI.
- `uid.dart` — shared `uuid` `UuidGenerator` (`.v4()`) backed by `Random.secure()`.
- `TimeAgoExt.timeAgo`/`timeAgoShort` — relative-time formatting via `timeago`.
- `Tappable` widget — ripple/opacity/scale/none tap-feedback wrapper.
- `AnimatedCounter` widget — animates an `int` between successive values.
- `Debouncer`, `DebounceFunction.debounce()` — callback debouncing.
- `NumDurationExt` — `200.ms`, `3.seconds`, `1.5.days` shorthand `Duration` getters.
- `UpdateListExt.updateWith` — find-and-update/insert/delete on a `List<T>`.
- `BuildContext.isLight`/`isDark`/`adaptiveColor`/`reversedAdaptiveColor`/`customAdaptiveColor`.
- `logE`/`logW`/`logI`/`logD` — general app-level logging on top of `logger`.
- `FormInput<T>`/`FormValidation` — dependency-free formz-style field validation, plus ready-made validators: `EmailInput`, `PasswordInput`, `UsernameInput`, `OtpInput`, `RequiredInput`, `IndonesianPhoneInput`.
- `AppFlavorEnv`/`AppFlavor` — typed per-flavor config resolver (`get<T>`/`require<T>`).
- `BlurHash` — pure-Dart encode/decode, verified against the reference `woltapp/blurhash` implementation.
- New dependencies: `uuid`, `timeago` (both zero-cost — only pulled in by the extensions/util above).

## 3.0.0 — 2026-06-21

### Breaking Changes — identifier renames

Public identifiers were renamed so each name reflects its value/role. Update call sites accordingly:

- Entry-point class `FlutterCore` → `FlutterCorekit` (matches the package name)
- `FlutterCorekit.localStorage` → `FlutterCorekit.secureStorage`; `FlutterCorekit.cleanup()` → `resetInitialization()`
- `ThemeProvider.setThemeMode(bool)` → `setDarkMode(bool)`
- `Failure.error` field → `Failure.cause` (all subclasses + `NetworkException`)
- `Result` failure variant `Error` → `ResultError` (avoids shadowing `dart:core.Error`)
- `ConnectivityService.getCurrentConnectivity()` → `getCurrentConnectivityResults()`
- `DioClient.authToken` getter → `authorizationHeader` (returns the `Bearer …` header)
- `ColorSchemes.purple/orange/darkBlue/darkGreen` → `…Scheme`
- Date ext: `toDbFormat` → `toIsoDate`, `toDateTime` → `toIndonesianDateTimeString`, `toIndonesiandMMMyyyy` → `toShortMonthNameWithDay`
- Number ext: `toFormattedString` → `toGroupedDigits`
- String ext: `toRemove62` → `withoutCountryCode62`, `toPhoneNumber62` → `toIndonesianPhoneDigits`, `jsonDecode` → `decodedJson`
- `BuildContext.accentIconTheme` → `secondaryIconTheme`; `canBack` → `canGoBack`; `withOpacity` → `colorWithOpacity`
- Num ext: `paddingX/paddingY` → `paddingHorizontal/paddingVertical`, `radiusX` → `radiusHorizontal`
- TextStyle ext: `heightSpace` → `withLineHeight`, `letterSpace` → `withLetterSpacing`
- Map ext: `get(key)` → `valueOrNull(key)`
- Navigation ext: `maybeBack` → `popToRoot`; `isDialogOpen` → `isCoveredByRoute`; `closeDialog` → `dismissTopRoute`
- Stream ext: `debounceMs(int)`/`throttleMs(int)` → `debounce(Duration)`/`throttle(Duration)`
- `UiHelper.shadow` → `defaultBoxShadow`; `insetAxis(x,y)` → `insetSymmetric(horizontal,vertical)`; `visualDensity(x,y)` → `visualDensity(horizontal,vertical)`
- `kDelayed` (one-shot future) → `defaultDelay()` (returns a fresh delay each call)
- `SecureStorage.deleteBoxFromDisk()` removed (use `clearBox()`)
- Extensions renamed from `…X` to descriptive names (`IterableX` → `NullableIterableExtension`, `StreamX` → `StreamExtension`, etc.)

### Fixes
- `BuildContext.isWeb` now uses `kIsWeb` (previously always reported Linux).
- `ThemeData` is now built with the custom `ColorScheme` directly, so scheme-derived
  colors (scaffold/app bar) match `FcColors`.
- Token refresh inherits client timeouts and clears the stale auth header when refresh fails.
- Logging interceptor redacts `Authorization`/`Cookie` headers and truncates bodies.
- `ThousandsFormatter` formats values beyond the `int` range and honors `allowNegative`.
- `SecureStorage.get<bool>` returns `null` for corrupt values instead of silently `false`.
- `defaultDelay()` delays on every call; stream `debounce`/`throttle` no longer leak the source subscription.

---

## 2.0.0 — 2026-06-20

### Breaking Changes
- **Package renamed `flutter_core` → `flutter_corekit`** (the `flutter_core` name
  is taken on pub.dev). Update imports to
  `package:flutter_corekit/flutter_corekit.dart`.
- **`ThemeProvider`**: removed the no-op `setColorScheme` / `currentColorScheme`
  (they never affected the theme) and the public `themeBoxName` / `localStorage`
  fields. Theme mode is now persisted via **`shared_preferences`** (a non-secret
  UI preference) instead of secure storage — much faster. Key: `themeKey`.
- **Removed `UseCase` / `NoParams`** (`lib/src/usecase/`). The base class was
  unused, untested, and its cooperative-cancellation feature was non-functional
  (the running `execute()` never observed `cancel()`). It also conflicted with
  the package's own principle of not shipping abstractions that compete with the
  modern Flutter ecosystem (Riverpod/Bloc + repositories). Bring your own
  use-case base class if you need one — `Result` / `Failure` remain exported.
- **`TimeoutException` → `NetworkTimeoutException`** (M10) to stop shadowing
  `dart:async`'s `TimeoutException`.
- **`LocalStorage` → `SecureStorage`** (M2), file `storage/local_storage.dart` →
  `storage/secure_storage.dart`. `LocalStorage` remains as a `@Deprecated`
  typedef alias for now. The rename makes it explicit that this is encrypted
  secure storage (flutter_secure_storage), not general key-value storage.
- **Connectivity pre-flight is now opt-in** (M3):
  `DioClient(checkConnectivityBeforeRequest: false)` by default. See below.

### New Features
- **`DioClient` / `FlutterCore.initialize`**: optional `Interceptor? interceptor`
  parameter to inject a custom Dio interceptor (ported from `main`'s
  `feat(network)` work and adapted to the refactored layout).

### API & design cleanup (M2, M3, M7, M9, M10)
- **Fixed duplicate `back()` on `BuildContext` (M9):** it was defined on both
  `NavigationExtension` and `DialogsAndAlerts`, making `context.back()` ambiguous
  for anyone importing the extensions barrel. It now lives only on
  `NavigationExtension`.
- **Trimmed barrel re-exports (M7):** `google_fonts` and `intl` are no longer
  re-exported from `package:flutter_core/flutter_core.dart` — they're internal
  implementation details. `dio`, `connectivity_plus`, and `flutter_screenutil`
  are still re-exported because their types appear in the public API. If you
  used `Intl`/`GoogleFonts` via the barrel, import those packages directly.
- **`SecureStorage`** now documents its performance/security caveats (slow,
  bulk ops decrypt all keys, web is not strongly protected) and gained
  `List<dynamic>` support.
- **Connectivity pre-flight off by default**: `connectivity_plus` reports the
  network interface, not real reachability (a captive portal reads "online"),
  and the check added a platform-channel round-trip per request. With it off, a
  failed connection still surfaces as `NoInternetConnectionException` (mapped
  from Dio's `connectionError`). Re-enable with
  `DioClient(checkConnectivityBeforeRequest: true)`.

### Unified error model (M1)
- **`Failure` is now the single error currency.** `NetworkException` (and all its
  subtypes — `UnauthorizedException`, `NotFoundException`, …) now **extend
  `Failure`**, so network errors flow directly into the `Result<T, Failure>`
  domain model without a lossy remap.
- **`ApiResponse.toResult()`** bridges the HTTP transport type into
  `Result<T?, Failure>`. `ApiResponse` remains the `DioClient` return type
  because HTTP allows a *success with no body* (204) that `Result.Success<T>`
  can't represent; the two now share one error type and convert cleanly.
- **Removed the dead, unexported `network/safe_call.dart`** (the duplicate
  helper) and the unused `ResponseExtension`. `safeRemoteCall` no longer
  re-wraps `NetworkException` into a generic `NetworkFailure` — it returns the
  specific failure as-is.

### Security & reliability (production hardening)
- **Retries are now idempotency-aware** (`RetryOptions.retryableMethods`,
  default `{GET, HEAD, OPTIONS}`). Non-idempotent requests (POST/PUT/PATCH/...)
  are **no longer auto-retried** on timeout/5xx — which previously risked
  **duplicate transactions** (double payment/order). A request can opt in with
  `Options(extra: {'retry': true})` when it's safe. Backoff now adds **jitter**
  (`RetryOptions.useJitter`, default on) to avoid a thundering herd.
- **Token refresh is coalesced.** Concurrent 401s now share a single in-flight
  refresh instead of each firing its own — preventing a refresh **stampede**
  that (with single-use/rotating tokens) logged users out at random. A
  per-request guard also prevents infinite refresh→retry loops.
- **GET cache is bounded and identity-scoped.** The in-memory cache now has an
  LRU bound (`DioClient(maxCacheEntries: 100)`) so it can't grow without limit,
  and cache keys include the auth-token identity so a cached response for one
  user can never be served to another after the token changes.
- **No more PII in logs.** `safeRemoteCall` no longer logs full response bodies
  (which routinely contain PII/tokens); remaining error logs are gated to debug
  builds only.

### Changed
- Reorganized `lib/src/domain/` into content-matched folders (no `domain/`):
  `result/failures.dart`, `result/result.dart`, `usecase/usecase.dart` (now
  removed), and `network/safe_remote_call.dart` (was `domain/safe_call.dart`,
  renamed to avoid colliding with `network/safe_call.dart`).
- Fixed broken import/export paths left by the `src/core/*` → `src/*` move; the
  package now compiles and the full test suite passes.
- Added GitHub Actions CI (format, analyze, test, publish dry-run).
- Bumped `google_fonts` `^6.1.0` → `^8.0.0` (the pinned 6.2.1 failed to compile
  under the current Dart SDK).

### Merge note
- Merged `main`'s `feat(network): integrate response caching and custom
  interceptors`. The custom-interceptor part was kept (see above). The
  **Hive-backed persistent HTTP cache** (`DioCacheConfig` +
  `dio_cache_interceptor` + `dio_cache_interceptor_hive_store` + `hive` /
  `hive_flutter`) was **not** re-introduced — it conflicts with this refactor's
  deliberate dependency reduction and the lightweight in-memory GET cache
  (`cacheTtl` / `forceRefresh`). The two GET-caching strategies are mutually
  exclusive; revisit if persistent HTTP caching is desired.

---

## 1.2.0 — 2026-06-19

### Breaking Changes
- **`DioClient`**: Removed the dual throw-based API (`get/post/put/delete/patch` returning `Response<T>`) and the verbose `*WithSafeCallApi` methods. All HTTP methods now return `ApiResponse<T>` — no try-catch needed at the call site.
- **`DioClient.post/put/delete/patch`**: Body parameter renamed from `data` to `body` for clarity.
- **`DioClient`**: `dataBuilder` (required) replaced by `fromJson` (optional). If omitted, `response.data` is returned as-is.
- **`ApiResponse.isSuccessful`**: Now returns `error == null` (was `data != null && error == null`). A successful 204 No Content response is now correctly `isSuccessful = true` with `data = null`.
- **`ApiResponse.success`**: Factory now accepts an optional argument — `ApiResponse.success()` creates a success with `null` data.
- **`FlutterCore.initialize`**: `cacheMaxAge` parameter removed (was unused since `dio_cache_interceptor` was dropped in 1.1.0).
- **Deleted**: 8 internal Clean Architecture files that were not publicly exported (see Removed section).

### New Features
- **`DioClient` in-memory GET cache**: `cacheTtl` parameter caches responses per URL + query parameters. `forceRefresh: true` bypasses the cache.
- **`DioClient.clearCache()`**: Clears all cached responses.
- **`DioClient.invalidateCache(path)`**: Removes a single cache entry.
- **`ApiResponse.when()`**: Exhaustive handler directly on `ApiResponse` — `result.when(onSuccess: ..., onFailure: ...)`.

### Removed
- Deleted internal Clean Architecture boilerplate (not publicly exported, not needed for MVVM):
  - `lib/src/core/data/datasources/base_local_data_source.dart`
  - `lib/src/core/data/datasources/base_remote_data_source.dart`
  - `lib/src/core/data/models/base_model.dart`
  - `lib/src/core/data/repositories/base_repository_impl.dart`
  - `lib/src/core/data/repositories/data_source_strategy.dart`
  - `lib/src/core/domain/entities/base_entity.dart`
  - `lib/src/core/domain/repositories/base_repository.dart`
  - `lib/src/core/domain/usecases/example_use_case.dart`
- Corresponding test files for the above removed

### Architecture Change: MVVM-friendly
The package no longer ships an opinionated Clean Architecture scaffold. Instead:
- Use `DioClient` directly in your repository classes
- Return `ApiResponse<T>` or map to `Result<T, Failure>` using `safeRemoteCall`
- Keep `Failure`, `Result`, `UseCase` for domain logic where needed — they're still exported

---

## 1.1.0 — 2026-06-18

### Bug Fixes
- **`LocalStorage`**: Fixed `get<Map<String, dynamic>>()` throwing `UnsupportedError` — Map type is now properly deserialized via `jsonDecode`
- **`Failure`**: Fixed `statusCode` default from `200` (HTTP OK) to `0` (no status code)
- **`safeRemoteCall`**: Fixed fallback error returning `AuthFailure` instead of `GenericFailure` when no failure context is available
- **`safeCall`** (network): Fixed redundant nested `DioException` construction
- **`ui_ext.dart`**: Fixed compile error — `inputDecorationTheme` return type updated to `InputDecorationThemeData` (breaking change in Flutter 3.27+)
- **`ResultExtension.when()`**: Fixed unsafe cast replaced with `is` type check

### New Features
- **`LocalStorage.getAllValues<T>()`**: New method to retrieve all key-value pairs in a box as a typed map
- **`StringExt.isValidEmail`**: New getter for email validation
- **`StringExt.isValidIndonesianPhone`**: New getter for Indonesian phone number validation
- **`Result.map<R>()`**: New extension method to transform success values
- **`Result.mapFailure<G>()`**: New extension method to transform failure values
- **`DioRetryInterceptor`**: Retry interceptor is now active — automatic retry with exponential backoff (3 attempts by default on timeouts and 5xx errors)
- **`DioClient`**: New `retryOptions` parameter to configure retry behavior

### Improvements
- **`stream_ext.dart`**: Replaced `rxdart` dependency with native Dart `StreamController` — no external dependency required for debounce/throttle
- **`maskEmail()`**: Fixed separator between masked local and domain parts
- **`UseCase`**: Renamed generic type parameter `Type` → `Output` to avoid shadowing Dart's built-in `Type` class

### Removed
- **`rxdart`** dependency removed (debounce/throttle reimplemented natively)
- **`dio_cache_interceptor`** dependency removed (cache config was commented-out)
- **`path_provider`** dependency removed (only referenced in deleted stub files)
- Deleted stub files that were 100% commented-out:
  - `lib/src/core/network/dio_cache_config.dart`
  - `lib/src/core/storage/secure_storage_service.dart`
  - `lib/src/core/storage/key_manager.dart`
  - `lib/src/core/services/storage_service.dart`
- Removed re-export of `rxdart` from public API
- Cleaned up all commented-out `remoteCallWrapper` blocks in `BaseRepositoryImpl`
- Removed development notes (`🚀 UPDATED`) from production code

### Breaking Changes
- `UseCase<Type, Params>` → `UseCase<Output, Params>` — rename type parameter
- `Failure.statusCode` default changed from `200` to `0`
- `rxdart` is no longer re-exported from `flutter_core.dart` — add `rxdart` directly to your app if needed
- Deleted stub files are no longer exported

---

## 1.0.3 — 2025-xx-xx

- Fix default status codes, improve error handling
- Add Indonesian date formats
- Refine UI widgets

## 1.0.0 — 2025-xx-xx

- Initial stable release
