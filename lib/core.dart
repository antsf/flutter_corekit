/// Exports core functionalities, services, and UI utilities for Flutter applications.
///
/// This library serves as the main entry point for the `flutter_corekit` package.
/// It provides the [FlutterCorekit] class for initializing essential services like
/// networking and storage, and the [ScreenUtilWrapper] widget for setting up
/// responsive UI utilities.
///
/// ## Usage
///
/// Before using any services from this package, you must initialize [FlutterCorekit]:
///
/// ```dart
/// import 'package:flutter_corekit/flutter_corekit.dart';
/// import 'package:flutter/material.dart';
///
/// void main() async {
///   // Ensure Flutter bindings are initialized for async operations before runApp.
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize Flutter Core services (e.g., network, storage).
///   await FlutterCorekit.initialize(baseUrl: 'https://api.example.com');
///
///   runApp(MyApp());
/// }
/// ```
///
/// Then, wrap your root widget (usually `MaterialApp`) with [ScreenUtilWrapper]
/// to enable responsive screen sizing:
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ScreenUtilWrapper(
///       // designSize is optional, defaults to 375x812
///       child: MaterialApp(
///         home: MyHomePage(),
///       ),
///     );
///   }
/// }
/// ```
library;

import 'package:dio/dio.dart' show Dio, Interceptor;
import 'package:flutter/material.dart';
import 'package:flutter_corekit/src/storage/secure_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

import 'src/network/dio_client.dart';
import 'src/services/connectivity_service.dart';

/// Main class for initializing and accessing core functionalities of the Flutter Core package.
///
/// This class provides static methods to initialize services like networking
/// ([dioClient]) and secure storage ([secureStorage]).
///
/// The [initialize] method **must** be called before accessing any services.
///
/// Accessing services before initialization will result in a [LateInitializationError].
class FlutterCorekit {
  static bool _isInitialized = false;
  static int _lifecycleGeneration = 0;
  static Future<void>? _initialization;
  static _CoreServices _services = _CoreServices();
  static DioClient? _initializingClient;

  /// Available after initialization completes. Access before initialization,
  /// after failure, and after reset throws a [LateInitializationError].
  static DioClient get dioClient => _services.dioClient;

  /// Available after initialization completes. Access before initialization,
  /// after failure, and after reset throws a [LateInitializationError].
  static SecureStorage get secureStorage => _services.secureStorage;

  /// Initializes storage, networking and the initial connectivity check.
  /// Concurrent callers share one Future and the first caller's options win;
  /// initialized calls are no-ops. Failures publish no partial services and
  /// permit retry. Reset invalidates in-flight work with [StateError], never
  /// publishing stale services. Timeouts are in milliseconds.
  static Future<void> initialize({
    required String baseUrl,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
    bool enableLogging = true,
    Interceptor? interceptor,
    Future<String?> Function(Dio)? refreshToken,
  }) {
    if (_isInitialized) return Future<void>.value();
    final active = _initialization;
    if (active != null) return active;
    final pending = _initializeServices(
      generation: _lifecycleGeneration,
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      enableLogging: enableLogging,
      interceptor: interceptor,
      refreshToken: refreshToken,
    );
    _initialization = pending;
    void clearPending() {
      if (identical(_initialization, pending)) _initialization = null;
    }

    pending.then<void>((_) => clearPending(),
        onError: (Object error, StackTrace stack) => clearPending());
    return pending;
  }

  static Future<void> _initializeServices({
    required int generation,
    required String baseUrl,
    required int connectTimeout,
    required int receiveTimeout,
    required bool enableLogging,
    required Interceptor? interceptor,
    required Future<String?> Function(Dio)? refreshToken,
  }) async {
    final storage = SecureStorage();
    DioClient? client;
    try {
      await storage.init();
      _checkGeneration(generation);
      client = DioClient(
        baseUrl: baseUrl,
        connectTimeoutMs: connectTimeout,
        receiveTimeoutMs: receiveTimeout,
        enableLogging: enableLogging,
        logger: Logger(
            printer: PrettyPrinter(
          methodCount: 0,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        )),
        interceptor: interceptor,
        refreshToken: refreshToken,
      );
      _initializingClient = client;
      await ConnectivityService.instance.hasConnection();
      _checkGeneration(generation);
      _services = _CoreServices.ready(client, storage);
      _isInitialized = true;
    } catch (_) {
      client?.clearAuthToken();
      client?.dioInstance.close(force: true);
      rethrow;
    } finally {
      if (identical(_initializingClient, client)) _initializingClient = null;
    }
  }

  static void _checkGeneration(int generation) {
    if (generation != _lifecycleGeneration) {
      throw StateError('FlutterCorekit initialization invalidated by reset.');
    }
  }

  /// Invalidates pending initialization, clears auth/cache and closes the
  /// owned Dio client. Services become unavailable until initialize completes
  /// again. A stale initialize Future fails with [StateError] when its pending
  /// dependency finishes; it cannot overwrite the replacement lifecycle.
  /// Persisted user data and shared theme services are not cleared.
  static Future<void> resetInitialization() async {
    final published = _isInitialized ? _services.dioClient : null;
    final initializing = _initializingClient;
    _lifecycleGeneration++;
    _initialization = null;
    _initializingClient = null;
    _services = _CoreServices();
    _isInitialized = false;
    for (final client in {published, initializing}.whereType<DioClient>()) {
      client.clearAuthToken();
      client.dioInstance.close(force: true);
    }
  }
}

class _CoreServices {
  _CoreServices();
  _CoreServices.ready(this.dioClient, this.secureStorage);
  late final DioClient dioClient;
  late final SecureStorage secureStorage;
}

/// A wrapper widget that initializes [ScreenUtil] for responsive UI development.
///
/// Place this widget at the root of your application, typically wrapping your [MaterialApp]
/// or [CupertinoApp]. It enables the use of `.w`, `.h`, and `.sp` extensions on numbers
/// for creating responsive dimensions and font sizes based on a design draft size.
///
/// Example:
/// ```dart
/// ScreenUtilWrapper(
///   designSize: const Size(360, 690), // Your design draft size
///   child: MaterialApp(
///     home: HomeScreen(),
///   ),
/// )
/// ```
class ScreenUtilWrapper extends StatelessWidget {
  /// The widget below this widget in the tree, typically your main app widget.
  final Widget child;

  /// The size of the device screen in the design draft, in logical pixels.
  /// Defaults to `Size(375, 812)` (e.g., iPhone X/XS/11 Pro).
  final Size designSize;

  /// Whether to adapt text size based on the screen width or the smaller of width/height.
  /// Defaults to `true`.
  final bool minTextAdapt;

  /// Whether to support screen splitting for foldable and large screen devices.
  /// Defaults to `true`.
  final bool splitScreenMode;

  /// Creates a [ScreenUtilWrapper].
  ///
  /// - [child]: The widget to be wrapped (required).
  /// - [designSize]: The screen size of the design draft (defaults to 375x812).
  /// - [minTextAdapt]: Controls text adaptation behavior (defaults to true).
  /// - [splitScreenMode]: Enables support for split screen mode (defaults to true).
  const ScreenUtilWrapper({
    super.key,
    required this.child,
    this.designSize = const Size(375, 812), // Corresponds to iPhone X/XS/11 Pro
    this.minTextAdapt = true,
    this.splitScreenMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: minTextAdapt,
      splitScreenMode: splitScreenMode,
      // The builder ensures that the child is built within the ScreenUtil context,
      // making ScreenUtil available to all descendants.
      // builder: (_, widgetChild) =>
      //     widgetChild!, // widgetChild is the 'child' passed to ScreenUtilInit
      child: child, // This is the 'child' property of ScreenUtilWrapper
    );
  }
}
