# flutter_corekit

A comprehensive Flutter core package providing theme management, network handling, secure storage, and UI extensions optimized for Indonesian Flutter apps.

> Formerly `flutter_core` (renamed in 2.0.0 — that name was taken on pub.dev).

[![pub.dev](https://img.shields.io/pub/v/flutter_corekit.svg)](https://pub.dev/packages/flutter_corekit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- **Theme Management** — light/dark mode with persistence, Material 3, custom color schemes, responsive typography (Google Fonts Inter)
- **Network Layer** — Dio-based HTTP client with automatic retry (exponential backoff), token refresh, connectivity pre-flight, structured error hierarchy
- **Secure Storage** — flutter_secure_storage wrapper with box namespacing, type-safe API, and `Map<String, dynamic>` support
- **Extensions** — 20+ extension files for `DateTime`, `num`, `String`, `Color`, `Uri`, `BuildContext`, navigation, dialogs, UI layout, streams, and more
- **Widgets** — `Tappable` (ripple/opacity/scale tap feedback) and `AnimatedCounter`
- **Form Validation** — dependency-free `FormInput<T>` pattern with ready-made validators (email, password, username, OTP, Indonesian phone)
- **App Flavors** — typed per-environment config resolver (`AppFlavor`/`AppFlavorEnv`)
- **BlurHash** — pure-Dart encode/decode, no image-decoding dependency
- **Result Type** — lightweight `Result<T, Failure>` with `Success`/`Error`, `when`/`map`, and a `Failure` hierarchy for clean, try-catch-free error handling
- **Indonesian Locale** — built-in Rupiah formatting, Indonesian date formats, phone number utilities

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_corekit:
    git:
      url: https://github.com/antsf/flutter_corekit
      ref: main
```

Import everything from one place:

```dart
import 'package:flutter_corekit/flutter_corekit.dart';
```

## Usage

### Theme Setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeProvider.instance.loadThemeMode();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider.instance,
      builder: (context, _) => MaterialApp(
        // ThemeProvider exposes a single already-resolved theme; toggle it with
        // ThemeProvider.instance.toggleTheme() / setDarkMode(bool).
        theme: ThemeProvider.instance.currentTheme,
        home: const HomePage(),
      ),
    );
  }
}
```

### Network Requests

```dart
final client = DioClient(
  baseUrl: 'https://api.example.com',
  retryOptions: const RetryOptions(maxAttempts: 3),
  refreshToken: (dio) async {
    final res = await dio.post('/auth/refresh');
    return res.data['accessToken'];
  },
);

client.setAuthToken('your_token');

// All methods return ApiResponse<T> — no try-catch needed
final result = await client.get('/users/me',
  fromJson: (data) => User.fromJson(data),
);
result.when(
  onSuccess: (user) => print(user?.name),
  onFailure: (err) => print(err.message),
);

// GET with 5-minute in-memory cache
final users = await client.get('/users',
  fromJson: (data) => (data as List).map(User.fromJson).toList(),
  cacheTtl: const Duration(minutes: 5),
);

// POST / PUT / PATCH — use `body:` for request payload
final created = await client.post('/users',
  body: {'name': 'Andi', 'email': 'andi@example.com'},
  fromJson: (data) => User.fromJson(data),
);

// DELETE — response body optional
final deleted = await client.delete('/users/123');
if (deleted.isSuccessful) print('User deleted');

// Cache management
client.invalidateCache('/users');
client.clearCache();
```

### Secure Storage

> `SecureStorage` is encrypted (flutter_secure_storage) — use it for small
> sensitive values (tokens, keys), not as a general app database. Bulk helpers
> read/decrypt all keys, and the web has no OS keychain.

```dart
final storage = SecureStorage();

// Store and retrieve typed values
await storage.set<String>('auth', 'token', 'eyJhbGci...');
await storage.set<bool>('settings', 'darkMode', true);
await storage.set<Map<String, dynamic>>('user', 'profile', {'name': 'Andi'});

final token = await storage.get<String>('auth', 'token');
final profile = await storage.get<Map<String, dynamic>>('user', 'profile');

// Get all values in a box
final allSettings = await storage.getAllValues<bool>('settings');

// Clear entire box
await storage.clearBox('auth');
```

### Extensions

#### DateTime (Indonesian locale)

```dart
DateTime.now().toIndonesianDate()        // "26 Juni 2025"
DateTime.now().toShortMonthName()        // "26 Jun 2025"
DateTime.now().toIndonesianDateWithDay() // "Kamis, 26 Juni 2025"
DateTime.now().toTime()                  // "14:30"
DateTime.now().toIsoDate()               // "2025-06-26"
```

#### Numbers (Rupiah)

```dart
60000.toRupiah()          // "Rp 60.000"
1500000.toShortRupiah()   // "Rp 1,5jt"
6500.toK()                // "6,5K"
```

#### Strings

```dart
'john.doe@example.com'.maskEmail()      // "jxxxxxxx@xxxxple.com"
'081234567890'.maskPhoneNumber()         // "xxxxxxxxx890"
'081234567890'.formatPhoneNumber()       // "62 812 3456 7890"
'hello world'.capitalizeWords           // "Hello World"
'test@email.com'.isValidEmail           // true
'08123456789'.isValidIndonesianPhone    // true
```

#### Context (dialogs, navigation, UI)

```dart
// Dialogs
context.showLoadingDialog(message: 'Memuat...');
context.showErrorAlert('Terjadi kesalahan');
context.showSuccessAlert('Berhasil disimpan');
final confirmed = await context.showConfirmationDialog(
  message: 'Hapus data ini?',
  confirmText: 'Ya',
  cancelText: 'Tidak',
);
await context.showIndonesianDatePicker();

// Navigation
context.push(const NextPage());
context.pushReplacement(const HomePage());
context.back();

// Screen info
context.screenWidth
context.isTablet
context.isKeyboardVisible
context.isDarkMode
```

#### Layout & UI

```dart
// Spacing (multiples of kPadding = 16)
1.spacing        // SizedBox(16x16)
2.spacingHeight  // SizedBox(height: 32)
1.padding        // EdgeInsets.all(16)
1.paddingHorizontal // EdgeInsets.symmetric(horizontal: 16)
0.5.radius       // BorderRadius.circular(5)
```

#### Streams

```dart
searchController.stream
  .debounce(const Duration(milliseconds: 300))   // wait 300ms of silence
  .throttle(const Duration(milliseconds: 500))   // emit at most once per 500ms
```

### Result Type

```dart
// Clean error handling without try-catch
FutureResult<User> getUser(String id) async {
  final response = await _api.get('/users/$id');
  if (response.isSuccessful) {
    return Success(User.fromJson(response.data));
  }
  return const Error(NetworkFailure(message: 'Not found'));
}

// Usage
final result = await getUser('123');
result.when(
  onSuccess: (user) => print('Hello ${user.name}'),
  onFailure: (f) => print('Error: ${f.message}'),
);

// Transform
final name = result.map((user) => user.name);
```

### New Utilities (Unreleased)

```dart
// Hex color <-> Color
final c = '#FF5733'.toColor();      // Color, null if invalid
final hex = c!.toHex();             // '#FFFF5733'

// Bare-host URI -> https://
Uri.parse('example.com').withScheme; // https://example.com

// Secure random UUID v4
final id = uuid.v4();

// Relative time
DateTime.now().subtract(const Duration(minutes: 5)).timeAgo(); // '5 minutes ago'

// Tap feedback + animated counter widgets
Tappable(
  feedback: TappableFeedback.scale,
  onTap: () {},
  child: const Card(child: Text('Press me')),
);
AnimatedCounter(count: likeCount, builder: (context, value) => Text('$value'));

// Debounce
final debouncer = Debouncer(milliseconds: 300);
onChanged: (q) => debouncer.run(() => search(q));

// Duration shorthand
await Future.delayed(300.ms);

// Dependency-free form validation
final email = EmailInput.dirty('not-an-email');
email.isValid; // false
email.error;   // 'Email is not valid'

// Per-flavor config
final flavor = AppFlavor(
  env: AppFlavorEnv.production,
  values: {'baseUrl': 'https://api.example.com'},
);
final baseUrl = flavor.require<String>('baseUrl');

// BlurHash (pure-Dart, no image-decoding dependency)
final hashString = BlurHash.encode(rgbaPixels, width: 32, height: 32);
final decodedPixels = BlurHash.decode(hashString, width: 32, height: 32);
```

## API Reference

### Error model
Every error is a `Failure`. `NetworkException` and its subtypes **extend**
`Failure`, so network and domain errors share one type. Bridge an `ApiResponse`
to a `Result<T?, Failure>` with `apiResponse.toResult()`.

`NetworkException` types: `NetworkTimeoutException`, `NoInternetConnectionException`,
`UnauthorizedException`, `ForbiddenException`, `NotFoundException`,
`ConflictException`, `TooManyRequestsException`, `InternalServerErrorException`,
`BadGatewayException`, `ServiceUnavailableException`, `GatewayTimeoutException`,
`CancelledException`, `UnknownNetworkException`.

Plain `Failure` types: `ServerFailure`, `NetworkFailure`, `CacheFailure`,
`AuthFailure`, `ValidationFailure`, `GenericFailure`.

### RetryOptions

```dart
const RetryOptions(
  maxAttempts: 3,              // default
  baseDelayMs: 1000,           // default
  maxDelayMs: 10000,           // default
  useExponentialBackoff: true, // default
  useJitter: true,             // default — spreads retries to avoid a herd
  retryableStatusCodes: [408, 500, 502, 503, 504],  // default
  retryableMethods: {'GET', 'HEAD', 'OPTIONS'},     // default (idempotent only)
)
```

By default only idempotent methods are retried. To retry a specific
non-idempotent request, pass `Options(extra: {'retry': true})`.

## Dependencies

| Package | Purpose |
|---|---|
| `dio` | HTTP client |
| `connectivity_plus` | Network connectivity |
| `flutter_secure_storage` | Encrypted storage (`SecureStorage`) |
| `flutter_screenutil` | Responsive UI scaling |
| `google_fonts` | Inter font family (internal; not re-exported) |
| `intl` | Locale-aware formatting (internal; not re-exported) |
| `logger` | Structured logging |
| `uuid` | Secure random UUID generation (`uid.dart`) |
| `timeago` | Relative-time formatting (`TimeAgoExt`) |

## Contributing

Pull requests are welcome. Please open an issue first to discuss major changes.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
