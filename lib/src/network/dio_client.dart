import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'network_logging.dart';

import '../services/connectivity_service.dart';
import 'api_response.dart';
import 'dio_interceptor.dart';
import 'dio_retry_interceptor.dart';
import 'exceptions/network_exceptions.dart';

class _CacheEntry {
  final dynamic rawData;
  final DateTime expiresAt;

  _CacheEntry(this.rawData, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Dio-based HTTP client with connectivity checks, token refresh,
/// automatic retry, in-memory GET cache, and structured error handling.
///
/// All HTTP methods return [ApiResponse<T>] — no try-catch needed at the
/// call site.
///
/// ### Quick start
/// ```dart
/// final client = DioClient(
///   baseUrl: 'https://api.example.com',
///   refreshToken: (dio) async {
///     final res = await dio.post('/auth/refresh');
///     return res.data['accessToken'];
///   },
/// );
///
/// client.setAuthToken('your_token');
///
/// // GET with 5-minute in-memory cache
/// final result = await client.get(
///   '/users',
///   fromJson: (d) => User.fromJson(d),
///   cacheTtl: const Duration(minutes: 5),
/// );
///
/// result.when(
///   onSuccess: (user) => print(user?.name),
///   onFailure: (err) => print(err.message),
/// );
/// ```
class DioClient {
  final Dio _dio;
  final ConnectivityService _connectivityService;
  final Logger? _logger;

  /// In-memory GET cache. A [LinkedHashMap] preserves insertion order so the
  /// least-recently-used entry is always `keys.first` for LRU eviction.
  final _cache = <String, _CacheEntry>{};

  /// Maximum number of cached GET responses. Beyond this, the least-recently-
  /// used entry is evicted so the cache can't grow without bound.
  final int _maxCacheEntries;

  /// Whether to check connectivity before each request. Off by default — see
  /// the [DioClient] constructor docs for why.
  final bool _checkConnectivityBeforeRequest;

  /// A single in-flight token refresh, shared by all requests that hit a 401
  /// at the same time. Coalescing prevents a "refresh stampede" — concurrent
  /// 401s firing multiple simultaneous refreshes, which (with single-use /
  /// rotating refresh tokens) invalidate each other and log the user out.
  Future<String?>? _ongoingRefresh;
  int _sessionGeneration = 0;
  bool _hasCustomInterceptors = false;
  final Set<Interceptor> _cacheSafeInterceptors = {};
  Transformer? _cacheTransformer;
  int _transformerEpoch = 0;

  /// Creates a [DioClient].
  ///
  /// [checkConnectivityBeforeRequest] (default `false`): when `true`, a
  /// connectivity check runs before every request and short-circuits with a
  /// [NoInternetConnectionException] if offline. It's **off by default** because
  /// `connectivity_plus` reports the network *interface*, not real reachability
  /// (a Wi-Fi captive portal reports "online"), and it adds a platform-channel
  /// round-trip to every call. With it off, a genuinely failed connection still
  /// surfaces as a [NoInternetConnectionException] (mapped from Dio's
  /// `connectionError`) — just without the unreliable pre-flight.
  DioClient({
    required String baseUrl,
    Dio? dio,
    ConnectivityService? connectivityService,
    int connectTimeoutMs = 15000,
    int receiveTimeoutMs = 15000,
    Logger? logger,
    bool enableLogging = true,
    RetryOptions retryOptions = const RetryOptions(),
    Interceptor? interceptor,
    int maxCacheEntries = 100,
    bool checkConnectivityBeforeRequest = false,
    Future<String?> Function(Dio)? refreshToken,
  })  : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: Duration(milliseconds: connectTimeoutMs),
              receiveTimeout: Duration(milliseconds: receiveTimeoutMs),
            )),
        _connectivityService =
            connectivityService ?? ConnectivityService.instance,
        _maxCacheEntries = maxCacheEntries,
        _checkConnectivityBeforeRequest = checkConnectivityBeforeRequest,
        _logger = logger {
    _setupInterceptors(
      enableLogging: enableLogging,
      retryOptions: retryOptions,
      interceptor: interceptor,
      refreshTokenCallback: refreshToken,
    );
    _cacheSafeInterceptors.addAll(_dio.interceptors);
  }

  // --- HTTP Methods ---

  /// GET request. Pass [cacheTtl] to serve repeated calls from an in-memory
  /// cache. Use [forceRefresh] to bypass the cache for a single call.
  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(dynamic)? fromJson,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Duration? cacheTtl,
    bool forceRefresh = false,
  }) {
    if (cancelToken?.isCancelled ?? false) {
      return Future.value(ApiResponse.failure(
          NetworkException.fromDioException(cancelToken!.cancelError!)));
    }
    final generation = _sessionGeneration;
    final key = cacheTtl != null
        ? _cacheKey(path, queryParameters, options: options)
        : null;
    if (cacheTtl != null && !forceRefresh) {
      final entry = key == null ? null : _readCacheEntry(key);
      if (entry != null) {
        return Future.value(_parseResponse<T>(entry.rawData, fromJson));
      }
    }
    return _execute<T>(
      () => _dio.get(path,
          queryParameters: queryParameters,
          options: _sessionOptions(options),
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress),
      fromJson: fromJson,
      cacheKey: key,
      cacheTtl: cacheTtl,
      cacheGeneration: generation,
      canCache: () =>
          key != null &&
          _cacheKey(path, queryParameters, options: options) == key,
    );
  }

  /// POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    T Function(dynamic)? fromJson,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _execute(
        () => _dio.post(path,
            data: body,
            queryParameters: queryParameters,
            options: _sessionOptions(options),
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress),
        fromJson: fromJson,
      );

  /// PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    T Function(dynamic)? fromJson,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _execute(
        () => _dio.put(path,
            data: body,
            queryParameters: queryParameters,
            options: _sessionOptions(options),
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress),
        fromJson: fromJson,
      );

  /// DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _execute(
        () => _dio.delete(path,
            data: body,
            queryParameters: queryParameters,
            options: _sessionOptions(options),
            cancelToken: cancelToken),
        fromJson: fromJson,
      );

  /// PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    T Function(dynamic)? fromJson,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _execute(
        () => _dio.patch(path,
            data: body,
            queryParameters: queryParameters,
            options: _sessionOptions(options),
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress),
        fromJson: fromJson,
      );

  // --- File download ---

  /// Downloads a file from [urlPath] to [savePath].
  /// Throws [NetworkException] on failure (not wrapped in [ApiResponse]).
  Future<void> download(
    String urlPath, {
    required dynamic savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (_checkConnectivityBeforeRequest) await _checkConnectivity();
    try {
      await _dio.download(urlPath, savePath,
          queryParameters: queryParameters,
          options: _sessionOptions(options),
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress);
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (_) {
      logNetworkMetadata(
          _logger, Level.error, 'DioClient: download error; details omitted.');
      throw UnknownNetworkException(
          dioException:
              DioException(requestOptions: RequestOptions(path: urlPath)));
    }
  }

  // --- Cache management ---

  /// Clears all in-memory cached GET responses.
  void clearCache() => _cache.clear();

  /// Removes the cached response for [path] + optional [queryParameters].
  void invalidateCache(String path, {Map<String, dynamic>? queryParameters}) {
    // Conservatively invalidate all context variants in this bounded cache.
    clearCache();
  }

  // --- Token & headers ---

  void setAuthToken(String token) {
    _invalidateSession();
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _invalidateSession();
    _dio.options.headers.remove('Authorization');
  }

  void addHeader(String key, String value) {
    _invalidateSession();
    _dio.options.headers[key] = value;
  }

  void removeHeader(String key) {
    _invalidateSession();
    _dio.options.headers.remove(key);
  }

  void clearHeaders() {
    _invalidateSession();
    _dio.options.headers.clear();
  }

  void _invalidateSession() {
    _sessionGeneration++;
    _ongoingRefresh = null;
    clearCache();
  }

  String? get authorizationHeader =>
      _dio.options.headers['Authorization'] as String?;

  /// Direct access to the underlying [Dio] instance. Use with caution.
  Dio get dioInstance => _dio;

  // --- Private ---

  Options _sessionOptions(Options? options) {
    // Capture before Dio queues onRequest, so an immediate logout/account
    // switch cannot stamp old credentials as belonging to the new session.
    return (options ?? Options()).copyWith(extra: {
      ...?options?.extra,
      '__corekit_session_generation': _sessionGeneration,
      '__corekit_session_auth': authorizationHeader,
      '__corekit_explicit_auth': options?.headers?.keys
              .any((key) => key.toLowerCase() == 'authorization') ??
          false,
    });
  }

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic)? fromJson,
    String? cacheKey,
    Duration? cacheTtl,
    int? cacheGeneration,
    bool Function()? canCache,
  }) async {
    final generation = _sessionGeneration;
    try {
      if (_checkConnectivityBeforeRequest) await _checkConnectivity();
      if (generation != _sessionGeneration) {
        throw _staleSessionError(RequestOptions(path: ''));
      }
      final response = await request();
      if (generation != _sessionGeneration) {
        throw _staleSessionError(response.requestOptions);
      }
      final rawData = response.data;
      if (cacheKey != null &&
          cacheTtl != null &&
          rawData != null &&
          cacheGeneration == _sessionGeneration &&
          (canCache?.call() ?? true)) {
        _writeCacheEntry(cacheKey, _CacheEntry(rawData, cacheTtl));
      }
      return _parseResponse<T>(rawData, fromJson);
    } on NetworkException catch (e) {
      return ApiResponse.failure(e);
    } on DioException catch (e) {
      return ApiResponse.failure(NetworkException.fromDioException(e));
    } catch (_) {
      logNetworkMetadata(_logger, Level.error,
          'DioClient: unexpected error; details omitted.');
      return ApiResponse.failure(UnknownNetworkException(
          dioException:
              DioException(requestOptions: RequestOptions(path: ''))));
    }
  }

  ApiResponse<T> _parseResponse<T>(
      dynamic rawData, T Function(dynamic)? fromJson) {
    try {
      if (rawData == null) return ApiResponse.success();
      final parsed = fromJson != null ? fromJson(rawData) : rawData as T?;
      return ApiResponse.success(parsed);
    } catch (_) {
      logNetworkMetadata(_logger, Level.error,
          'DioClient: response parse error; details omitted.');
      return ApiResponse.failure(UnknownNetworkException(
          dioException:
              DioException(requestOptions: RequestOptions(path: ''))));
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await _connectivityService.hasConnection()) {
      throw NoInternetConnectionException(
        dioException: DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
          message: 'No internet connection.',
        ),
      );
    }
  }

  String? _cacheKey(String path, Map<String, dynamic>? query,
      {Options? options}) {
    final transformer = _dio.transformer;
    if (!identical(_cacheTransformer, transformer)) {
      clearCache();
      _cacheTransformer = transformer;
      _transformerEpoch++;
    }
    // Exact built-in types only: subclasses/callbacks may close over mutable
    // account or policy context. Function identity alone cannot partition it.
    final safeTransformer = transformer.runtimeType == FusedTransformer ||
        (transformer.runtimeType == SyncTransformer &&
            transformer is SyncTransformer &&
            identical(transformer.jsonDecodeCallback, jsonDecode) &&
            identical(transformer.jsonEncodeCallback, jsonEncode));
    if (!safeTransformer) {
      clearCache();
      _transformerEpoch++;
      return null;
    }
    if (_hasCustomInterceptors ||
        _dio.interceptors.any((i) => !_cacheSafeInterceptors.contains(i))) {
      clearCache();
      return null;
    }
    final request = (options ?? Options())
        .compose(_dio.options, path, queryParameters: query);
    // Decoder/encoder/status callbacks may close over identity or policy.
    // Their behavior is not a serializable part of a safe cache key.
    if (request.responseDecoder != null ||
        request.requestEncoder != null ||
        !identical(request.validateStatus, BaseOptions().validateStatus)) {
      clearCache();
      return null;
    }
    try {
      // Exact private in-memory identity, not collision-prone hashCode.
      // These keys are never exposed in logs or diagnostics.
      return jsonEncode([
        _sessionGeneration,
        _transformerEpoch,
        request.uri.toString(),
        _canonical(request.headers),
        _canonical(request.extra),
        request.responseType.name,
        request.contentType,
        request.followRedirects,
        request.maxRedirects,
        request.receiveDataWhenStatusError,
      ]);
    } on Object {
      return null; // Non-JSON context cannot be safely partitioned.
    }
  }

  Object? _canonical(Object? value) {
    if (value is Map<String, dynamic>) {
      return {
        for (final k in value.keys.toList()..sort()) k: _canonical(value[k])
      };
    }
    if (value is List) return value.map(_canonical).toList();
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw const FormatException('Unpartitionable request context');
  }

  /// Reads a cache entry, applying LRU semantics: a valid hit is moved to
  /// most-recently-used; an expired entry is dropped. Returns null on miss.
  _CacheEntry? _readCacheEntry(String key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;
    if (!entry.isValid) return null; // expired -> evicted
    _cache[key] = entry; // re-insert as most-recently-used
    return entry;
  }

  /// Writes a cache entry and evicts the least-recently-used entries once the
  /// cache exceeds [_maxCacheEntries].
  void _writeCacheEntry(String key, _CacheEntry entry) {
    _cache.remove(key); // ensure re-insertion updates recency order
    _cache[key] = entry;
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first); // eldest == least recently used
    }
  }

  void _setupInterceptors({
    required bool enableLogging,
    required RetryOptions retryOptions,
    Interceptor? interceptor,
    required Future<String?> Function(Dio)? refreshTokenCallback,
  }) {
    final defaultInterceptors = Interceptors();
    _hasCustomInterceptors = interceptor != null ||
        _dio.interceptors.any((i) => !defaultInterceptors.contains(i));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      request.extra.putIfAbsent(
          '__corekit_session_generation', () => _sessionGeneration);
      request.extra
          .putIfAbsent('__corekit_session_auth', () => authorizationHeader);
      if (!_isCurrentSession(request)) {
        return handler.reject(_staleSessionError(request));
      }
      handler.next(request);
    }));
    if (enableLogging && _logger != null) {
      _dio.interceptors
          .add(DioLoggingInterceptor(logger: _logger, enableLogging: true));
    }

    // Optional caller-supplied interceptor (e.g. a cache or auth interceptor).
    if (interceptor != null) {
      _dio.interceptors.add(interceptor);
    }

    if (refreshTokenCallback != null) {
      _dio.interceptors.add(InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Only attempt a refresh once per request — if the retried request
          // still 401s, fall through instead of looping forever.
          final alreadyRetried =
              error.requestOptions.extra['__retried_after_refresh'] == true;
          final generation =
              error.requestOptions.extra['__corekit_session_generation'];
          final sessionAuth =
              error.requestOptions.extra['__corekit_session_auth'];
          final canRefresh = generation == _sessionGeneration &&
              error.requestOptions.extra['__corekit_explicit_auth'] != true &&
              error.requestOptions.headers['Authorization'] == sessionAuth;
          if (error.response?.statusCode == 401 &&
              !alreadyRetried &&
              canRefresh) {
            logNetworkMetadata(_logger, Level.info,
                'DioClient: 401 received. Attempting token refresh.');
            try {
              // A parallel refresh already rotated this managed session.
              // Replay once with its current token; do not refresh again.
              if (sessionAuth != authorizationHeader) {
                final currentAuth = authorizationHeader;
                if (currentAuth == null) return handler.next(error);
                error.requestOptions.headers['Authorization'] = currentAuth;
                error.requestOptions.extra['__retried_after_refresh'] = true;
                return handler.resolve(await _dio.fetch(error.requestOptions));
              }
              final newToken = await _refreshAuthToken(refreshTokenCallback);
              if (generation != _sessionGeneration ||
                  (sessionAuth != authorizationHeader &&
                      authorizationHeader != 'Bearer $newToken')) {
                return handler.next(error);
              }
              if (newToken != null) {
                // Same session: do not invalidate concurrent refresh waiters.
                _dio.options.headers['Authorization'] = 'Bearer $newToken';
                clearCache();
                logNetworkMetadata(_logger, Level.info,
                    'DioClient: Token refreshed. Retrying request.');
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                error.requestOptions.extra['__retried_after_refresh'] = true;
                return handler.resolve(await _dio.fetch(error.requestOptions));
              }
              // Refresh definitively failed to produce a token: the current
              // token is invalid, so drop it instead of leaving a stale
              // Authorization header on every subsequent request.
              logNetworkMetadata(_logger, Level.warning,
                  'DioClient: Token refresh returned null. Clearing stale auth token.');
              clearAuthToken();
            } catch (_) {
              logNetworkMetadata(_logger, Level.error,
                  'DioClient: Token refresh failed; details omitted.');
            }
          }
          return handler.next(error);
        },
      ));
    }

    _dio.interceptors.add(DioRetryInterceptor(
      dio: _dio,
      options: retryOptions,
      logger: _logger,
      enableLogging: enableLogging,
      canRetry: _isCurrentSession,
    ));
  }

  bool _isCurrentSession(RequestOptions request) =>
      request.extra['__corekit_session_generation'] == _sessionGeneration;

  DioException _staleSessionError(RequestOptions request) => DioException(
        requestOptions: request,
        type: DioExceptionType.cancel,
        message: 'Session changed while request was in flight.',
      );

  /// Runs [callback] to obtain a fresh token, coalescing concurrent callers
  /// onto a single in-flight refresh. The first 401 starts the refresh; any
  /// other 401s that arrive while it is running await the same result instead
  /// of starting their own.
  Future<String?> _refreshAuthToken(Future<String?> Function(Dio) callback) {
    final active = _ongoingRefresh;
    if (active != null) return active;
    final generation = _sessionGeneration;
    final completer = Completer<String?>();
    final pending = completer.future;
    // Publish before invoking user code: even a synchronous throw can clean up.
    _ongoingRefresh = pending;
    () async {
      try {
        // Inherit the main client's timeouts so a hung refresh endpoint can't
        // stall all coalesced 401 callers indefinitely.
        final dioForRefresh = Dio(BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          sendTimeout: _dio.options.sendTimeout,
        ));
        completer.complete(await callback(dioForRefresh));
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        if (generation == _sessionGeneration &&
            identical(_ongoingRefresh, pending)) {
          _ongoingRefresh = null;
        }
      }
    }();
    return pending;
  }
}
