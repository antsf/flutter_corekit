# Contributing to flutter_corekit

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Run tests: `flutter test`
4. Run analysis: `flutter analyze`
5. Submit a pull request

## Branch Naming

| Prefix | Use case |
|---|---|
| `feat/` | New feature |
| `fix/` | Bug fix |
| `refactor/` | Code cleanup without behavior change |
| `docs/` | Documentation only |
| `test/` | Test additions or fixes |

## Code Guidelines

- No commented-out code in production files — delete or use a separate branch
- No development notes in source (`// TODO added for feature X`, emoji markers)
- Extensions go in `lib/src/extensions/` with corresponding test in `test/extensions/`
- New public API must be exported from `lib/flutter_corekit.dart`
- Follow existing naming: snake_case files, PascalCase classes, camelCase methods

## Adding a New Extension

1. Create `lib/src/extensions/your_ext.dart`
2. Add the export to `lib/src/extensions/extensions.dart`
3. Write tests in `test/extensions/your_ext_test.dart`

## LocalStorage Supported Types

When adding new type support to `LocalStorage._fromString<T>()`, also update `_toString<T>()` symmetrically and add a test case in `test/storage/local_storage_test.dart`.

Currently supported: `String`, `int`, `double`, `bool`, `Map<String, dynamic>`.

## Dependency Policy

Before adding a new dependency, ask:
1. Is it used in more than one file?
2. Is the functionality hard to implement natively?
3. Does it significantly increase package size for consumer apps?

Avoid adding dependencies for single-use utilities — implement them directly.

## Commit Messages

Use conventional commits:

```
feat: add isValidEmail getter to StringExt
fix: LocalStorage Map deserialization
refactor: remove unused remoteCallWrapper comments
docs: update README with retry examples
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a specific file
flutter test test/storage/local_storage_test.dart
```

Tests should cover:
- Happy path
- Edge cases (empty string, null, boundary values)
- Error cases (unsupported type, network failure)

## Before Submitting a PR

- [ ] `flutter analyze` shows no issues
- [ ] `flutter test` passes
- [ ] CHANGELOG.md updated under the appropriate version
- [ ] README.md updated if public API changed
- [ ] No commented-out code added

## Consumer app usage standard

If your app depends on `flutter_corekit`, use its features maximally — a raw
Flutter API is a defect, not a style choice, whenever this package already
provides the equivalent:

- **No raw `Theme.of(context)` / `MediaQuery.of(context).something`.** Use the
  `context.*` extensions (`color_scheme_ext.dart`, `text_theme_ext.dart`,
  `ui_ext.dart`): `context.theme`, `context.colorScheme`, `context.primaryColor`
  / `surfaceColor` / `errorColor` / `onSurfaceVariantColor` / etc.,
  `context.titleLarge` / `bodyMedium` / `labelSmall` / etc., `context.keyboardHeight`,
  `context.screenHeight`, `context.viewPadding`, `context.viewInsets`,
  `context.dialogTheme`, `context.bottomSheetTheme`, `context.inputDecorationTheme`.
  Exception: `MediaQuery.disableAnimationsOf(context)` /
  `MediaQuery.accessibleNavigationOf(context)` are the idiomatic Flutter form,
  not the banned pattern.
- **No raw `SizedBox`/`EdgeInsets`/`BorderRadius.circular` used for spacing,
  padding or radius.** Use the `num` extensions in `ui_ext.dart` (multiples of
  `kPadding`=16 / `kRadius`=10): `.spacing`/`.spacingWidth`/`.spacingHeight`,
  `.padding`/`.paddingHorizontal`/`.paddingVertical`/`.paddingLeft`/`.paddingTop`/
  `.paddingRight`/`.paddingBottom`, `.radius`/`.radiusTop`/`.radiusBottom`/
  `.radiusHorizontal`/`.cornerRadius`, and `[...].spaceBetween(...)` for list
  gaps (`widget_ext.dart`). A `SizedBox` that sizes real content — a touch
  target, an icon's fixed box, an image placeholder — is not a spacer; leave
  those alone. These extensions call flutter_screenutil's `.w`/`.h`, which
  throw `LateInitializationError` until `ScreenUtil` is configured once (the
  app root normally does this via `ScreenUtilInit`; widget tests need their
  own init — see this package's own `test/flutter_test_config.dart` and
  `test/test_helpers.dart` for the pattern).
- **Prefer this package's `Core*` widgets over the raw Material equivalent**
  whenever one exists: `CoreButton`, `CoreIconButton`, `CoreTextField` /
  `CorePasswordField`, `CoreChoiceGroup`, `CoreDialog`, `CoreBottomSheet`,
  `CoreSearchDropdown`, `CoreNotice` / `CoreSnackbar` / `CoreStatusBadge`,
  `CoreStateView`, `Tappable`, `AnimatedCounter` — not a hand-rolled
  equivalent built from raw Material widgets.
- Also prefer `ThemeProvider`, `DioClient`/`ApiResponse`/`NetworkException`,
  `SecureStorage`, `FormInput`/validators, `Result`/`Failure`, and the
  extension files (navigation, dialogs/alerts, date, number, string, stream,
  duration) over a hand-rolled equivalent — see the README for the full list.

This package's own non-widget internals aren't fully compliant yet either
(e.g. `dialogs_and_alerts_ext.dart`'s `showLoadingDialog` still has a couple
of raw `SizedBox`/`EdgeInsets` and a raw `AlertDialog` instead of
`CoreDialog`) — a PR closing that gap is welcome.
