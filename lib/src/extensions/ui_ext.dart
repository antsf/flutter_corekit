/// UI and device adaptation extension methods for BuildContext and num.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/default.dart';

/// --- BuildContext Extensions ---
/// (Screen, theme, device info, insets, density, etc.)
/// Extension methods for [BuildContext] to access screen, theme, and device info.
extension BuildContextExtension on BuildContext {
  // Screen Information

  /// Gets the screen size of the device.
  Size get screenSize => MediaQuery.of(this).size;

  /// Gets the width of the screen.
  double get screenWidth => screenSize.width;

  /// Gets the height of the screen.
  double get screenHeight => screenSize.height;

  /// Gets the current orientation of the device (portrait or landscape).
  Orientation get orientation => MediaQuery.of(this).orientation;

  /// Checks if the device is in portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;

  /// Checks if the device is in landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Gets the device's pixel ratio.
  double get pixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Gets the text scaler for the current device.
  TextScaler get textScaler => MediaQuery.of(this).textScaler;

  // Safe Area and Insets

  /// Gets the safe area padding, which is the space not occupied by system UIs like the notch.
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Gets the view insets, which is the space occupied by system UIs.
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Gets the view padding, which is the space occupied by system UIs.
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;

  /// Gets the system gesture insets.
  EdgeInsets get systemGestureInsets => MediaQuery.of(this).systemGestureInsets;

  /// Gets the height of the status bar.
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// Gets the height of the bottom safe area, useful for the home indicator.
  double get bottomSafeAreaHeight => MediaQuery.of(this).padding.bottom;

  /// Gets the height of the on-screen keyboard.
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// Checks if the keyboard is currently visible.
  bool get isKeyboardVisible => keyboardHeight > 0;

  // Theme Access

  /// Gets the current theme data.
  ThemeData get theme => Theme.of(this);

  /// Gets the icon theme data from the current theme.
  IconThemeData get iconTheme => theme.iconTheme;

  /// Gets the primary icon theme data from the current theme.
  IconThemeData get primaryIconTheme => theme.primaryIconTheme;

  /// An icon theme derived from the color scheme's secondary color (at 70% alpha).
  IconThemeData get secondaryIconTheme =>
      IconThemeData(color: theme.colorScheme.secondary.withValues(alpha: .7));

  /// Gets the input decoration theme from the current theme.
  InputDecorationThemeData get inputDecorationTheme =>
      theme.inputDecorationTheme;

  /// Gets the button theme data from the current theme.
  ButtonThemeData get buttonTheme => theme.buttonTheme;

  /// Gets the elevated button theme data from the current theme.
  ElevatedButtonThemeData get elevatedButtonTheme => theme.elevatedButtonTheme;

  /// Gets the text button theme data from the current theme.
  TextButtonThemeData get textButtonTheme => theme.textButtonTheme;

  /// Gets the outlined button theme data from the current theme.
  OutlinedButtonThemeData get outlinedButtonTheme => theme.outlinedButtonTheme;

  /// Gets the dialog theme data from the current theme.
  DialogThemeData get dialogTheme => theme.dialogTheme;

  /// Gets the snack bar theme data from the current theme.
  SnackBarThemeData get snackBarTheme => theme.snackBarTheme;

  /// Gets the bottom sheet theme data from the current theme.
  BottomSheetThemeData get bottomSheetTheme => theme.bottomSheetTheme;

  /// Gets the popup menu theme data from the current theme.
  PopupMenuThemeData get popupMenuTheme => theme.popupMenuTheme;

  /// Gets the tooltip theme data from the current theme.
  TooltipThemeData get tooltipTheme => theme.tooltipTheme;

  /// Gets the chip theme data from the current theme.
  ChipThemeData get chipTheme => theme.chipTheme;

  /// Gets the card theme data from the current theme.
  CardThemeData get cardTheme => theme.cardTheme;

  /// Gets the divider theme data from the current theme.
  DividerThemeData get dividerTheme => theme.dividerTheme;

  /// Gets the bottom navigation bar theme data from the current theme.
  BottomNavigationBarThemeData get bottomNavigationBarTheme =>
      theme.bottomNavigationBarTheme;

  /// Gets the floating action button theme data from the current theme.
  FloatingActionButtonThemeData get floatingActionButtonTheme =>
      theme.floatingActionButtonTheme;

  /// Gets the navigation rail theme data from the current theme.
  NavigationRailThemeData get navigationRailTheme => theme.navigationRailTheme;

  /// Gets the material tap target size from the current theme.
  MaterialTapTargetSize get materialTapTargetSize =>
      theme.materialTapTargetSize;

  // Platform Detection

  /// Gets the target platform for the application.
  TargetPlatform get platform => theme.platform;

  /// Checks if the platform is iOS.
  bool get isIOS => platform == TargetPlatform.iOS;

  /// Checks if the platform is Android.
  bool get isAndroid => platform == TargetPlatform.android;

  /// Checks if the platform is macOS.
  bool get isMacOS => platform == TargetPlatform.macOS;

  /// Checks if the platform is Windows.
  bool get isWindows => platform == TargetPlatform.windows;

  /// Checks if the platform is Linux.
  bool get isLinux => platform == TargetPlatform.linux;

  /// Checks if the platform is Fuchsia.
  bool get isFuchsia => platform == TargetPlatform.fuchsia;

  /// Checks if the app is running on the web.
  ///
  /// Uses the compile-time constant `kIsWeb`, which is the only reliable way to
  /// detect web. (`platform` reports the host OS even in a browser.)
  bool get isWeb => kIsWeb;

  /// Checks if the platform is a desktop operating system.
  bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Checks if the platform is a mobile operating system.
  bool get isMobile => isIOS || isAndroid;

  // Device Type Detection

  /// Checks if the device is a tablet.
  bool get isTablet => isMobile && screenWidth >= 600;

  /// Checks if the device is a phone.
  bool get isPhone => isMobile && screenWidth < 600;

  /// Checks if the device is a watch.
  bool get isWatch => isIOS && screenWidth < 400;

  /// Checks if the device is a TV.
  bool get isTV => isAndroid && screenWidth >= 1200;

  /// Checks if the device is a car display.
  bool get isCar => isAndroid && screenWidth >= 800 && screenWidth < 1200;

  /// Checks if the device is a foldable phone.
  bool get isFoldable => isAndroid && screenWidth >= 600 && screenWidth < 800;

  /// Checks if the device is a wearable device (i.e. a watch).
  ///
  /// Note: TVs, car displays, and foldables are distinct form factors — use
  /// [isTV], [isCar], and [isFoldable] for those.
  bool get isWearable => isWatch;

  /// Checks if the device is a handheld device (phone or tablet).
  bool get isHandheld => isPhone || isTablet;

  // Screen Size Categories

  /// Checks if the screen is considered large (width >= 1200).
  bool get isLargeScreen => screenWidth >= 1200;

  /// Checks if the screen is considered medium (width >= 600 and < 1200).
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// Checks if the screen is considered small (width < 600).
  bool get isSmallScreen => screenWidth < 600;

  /// Checks if the screen is considered extra large (width >= 1600).
  bool get isExtraLargeScreen => screenWidth >= 1600;

  /// Checks if the screen is considered extra small (width < 400).
  bool get isExtraSmallScreen => screenWidth < 400;

  // Display Density

  /// Checks if the device has a high-resolution retina display.
  bool get isRetina => pixelRatio >= 2.0;

  /// Checks if the device has a high pixel density.
  bool get isHighDensity => pixelRatio >= 1.5;

  /// Checks if the device has a low pixel density.
  bool get isLowDensity => pixelRatio < 1.5;

  /// Checks if the device has a very high pixel density.
  bool get isExtraHighDensity => pixelRatio >= 3.0;

  /// Checks if the device has a very low pixel density.
  bool get isExtraLowDensity => pixelRatio < 1.0;

  /// Checks if the device has a normal pixel density.
  bool get isNormalDensity => pixelRatio >= 1.0 && pixelRatio < 1.5;

  /// Checks if the device has a medium pixel density.
  bool get isMediumDensity => pixelRatio >= 1.5 && pixelRatio < 2.0;

  // Brightness

  /// The current theme [Brightness].
  Brightness get brightness => theme.brightness;

  /// Whether the current theme [Brightness] is [Brightness.light].
  bool get isLight => brightness == Brightness.light;

  /// Whether the current theme [Brightness] is [Brightness.dark].
  bool get isDark => !isLight;

  /// Black in light mode, white in dark mode — a color that stays legible
  /// against the theme's default background regardless of brightness.
  Color get adaptiveColor => isDark ? Colors.white : Colors.black;

  /// The inverse of [adaptiveColor]: white in light mode, black in dark mode.
  Color get reversedAdaptiveColor => isDark ? Colors.black : Colors.white;
}

/// --- Num Extensions ---
/// (Spacing, padding, radius helpers)
/// Extension methods for [num] to provide spacing, padding, and radius helpers.
extension NumExtension on num {
  /// Returns a [SizedBox] with both width and height as multiples of [kPadding].
  Widget get spacing =>
      SizedBox(width: (this * kPadding).w, height: (this * kPadding).h);

  /// Returns a horizontal spacing widget.
  Widget get spacingWidth => SizedBox(width: (this * kPadding).w);

  /// Returns a vertical spacing widget.
  Widget get spacingHeight => SizedBox(height: (this * kPadding).h);

  /// Returns [EdgeInsets] with all sides as multiples of [kPadding].
  EdgeInsets get padding => EdgeInsets.all((this * kPadding).w);

  /// Returns [EdgeInsets] with horizontal sides as multiples of [kPadding].
  EdgeInsets get paddingHorizontal =>
      EdgeInsets.symmetric(horizontal: (this * kPadding).w);

  /// Returns [EdgeInsets] with a left padding as a multiple of [kPadding].
  EdgeInsets get paddingLeft => EdgeInsets.only(left: (this * kPadding).w);

  /// Returns [EdgeInsets] with a top padding as a multiple of [kPadding].
  EdgeInsets get paddingTop => EdgeInsets.only(top: (this * kPadding).w);

  /// Returns [EdgeInsets] with a right padding as a multiple of [kPadding].
  EdgeInsets get paddingRight => EdgeInsets.only(right: (this * kPadding).w);

  /// Returns [EdgeInsets] with a bottom padding as a multiple of [kPadding].
  EdgeInsets get paddingBottom => EdgeInsets.only(bottom: (this * kPadding).w);

  /// Returns [EdgeInsets] with horizontal sides as multiples of [kPadding].
  EdgeInsets get paddingVertical =>
      EdgeInsets.symmetric(vertical: (this * kPadding).w);

  /// Returns a [BorderRadius] with all corners as multiples of [kRadius].
  BorderRadius get radius => BorderRadius.circular((this * kRadius).r);

  /// Returns a [BorderRadius.horizontal] with all corners as multiples of [kRadius].
  BorderRadius get radiusHorizontal =>
      BorderRadius.horizontal(left: cornerRadius, right: cornerRadius);

  /// Returns a [BorderRadius.top] with all corners as multiples of [kRadius].
  BorderRadius get radiusTop => BorderRadius.vertical(top: cornerRadius);

  /// Returns a [BorderRadius.bottom] with all corners as multiples of [kRadius].
  BorderRadius get radiusBottom => BorderRadius.vertical(bottom: cornerRadius);

  /// Returns a [Radius] as a multiple of [kRadius].
  Radius get cornerRadius => Radius.circular((this * kRadius).r);
}

/// --- EdgeInsets Extensions ---
/// (Scaling)
/// Extension methods for [EdgeInsets] to provide scaling.
extension EdgeInsetsScaleExtension on EdgeInsets {
  /// Returns a scaled [EdgeInsets] using [ScreenUtil].
  EdgeInsets get scaled =>
      copyWith(left: left.w, right: right.w, top: top.h, bottom: bottom.h);
}

/// --- BorderRadius Extensions ---
/// (Scaling)
/// Extension methods for [BorderRadius] to provide scaling.
extension BorderRadiusScaleExtension on BorderRadius {
  /// Returns a scaled [BorderRadius] using [ScreenUtil].
  BorderRadius get scaled => BorderRadius.only(
        topLeft: Radius.circular(topLeft.x.r),
        topRight: Radius.circular(topRight.x.r),
        bottomLeft: Radius.circular(bottomLeft.x.r),
        bottomRight: Radius.circular(bottomRight.x.r),
      );
}

/// --- BoxShadow Extensions ---
/// (Scaling)
/// Extension methods for [BoxShadow] to provide scaling.
extension BoxShadowExtension on BoxShadow {
  /// Returns a scaled [BoxShadow] using [ScreenUtil].
  BoxShadow get scaled => BoxShadow(
        color: color,
        offset: Offset(offset.dx.w, offset.dy.h),
        blurRadius: blurRadius.r,
        spreadRadius: spreadRadius.r,
      );
}
