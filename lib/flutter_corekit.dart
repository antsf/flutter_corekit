library;

// Core initialization
export 'core.dart';

// Theme
export 'src/theme/theme.dart';
export 'src/theme/theme_provider.dart';
export 'src/theme/text_theme.dart';
export 'src/theme/color_schemes.dart';

// Failures & Result
export 'src/result/failures.dart';
export 'src/result/result.dart';

// Network exceptions & utilities
export 'src/network/exceptions/network_exceptions.dart';
export 'src/network/dio_client.dart';
export 'src/network/dio_retry_interceptor.dart';
export 'src/network/api_response.dart';
export 'src/network/safe_remote_call.dart';

// Services
export 'src/services/connectivity_service.dart';

// Storage
export 'src/storage/secure_storage.dart';

// Constants
export 'src/constants/constants.dart';

// Utils
export 'src/utils/utils.dart';

// Config
export 'src/config/app_flavor.dart';
export 'src/config/blur_hash.dart';

// Validation
export 'src/validation/validation.dart';

// Extensions
export 'src/extensions/extensions.dart';

// External packages re-exported because their types appear in this package's
// public API (or are needed to use it):
//  - dio: DioClient takes Options/CancelToken/ProgressCallback, returns types
//    built on Response/DioException, and exposes the raw Dio via dioInstance.
//  - connectivity_plus: ConnectivityResult is in ConnectivityService's API.
//  - flutter_screenutil: ScreenUtilWrapper + the .w/.h/.sp sizing extensions.
//
// google_fonts and intl are deliberately NOT re-exported — they're internal
// implementation details (fonts in the default theme, locale formatting in the
// extensions). Add them to your own pubspec if you need them directly.
export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:dio/dio.dart';
export 'package:flutter_screenutil/flutter_screenutil.dart';
