import 'package:flutter/material.dart';
import 'package:flutter_corekit/src/extensions/extensions.dart';

extension TextThemeExtensions on BuildContext {
  TextTheme get textTheme => theme.textTheme;

  // Display styles
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;

  TextStyle? get displayLargeBold =>
      textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get displayMediumBold =>
      textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get displaySmallBold =>
      textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get displayLargeItalic =>
      textTheme.displayLarge?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get displayMediumItalic =>
      textTheme.displayMedium?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get displaySmallItalic =>
      textTheme.displaySmall?.copyWith(fontStyle: FontStyle.italic);

  // Headline styles
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;

  TextStyle? get headlineLargeBold =>
      textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get headlineMediumBold =>
      textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get headlineSmallBold =>
      textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get headlineLargeItalic =>
      textTheme.headlineLarge?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get headlineMediumItalic =>
      textTheme.headlineMedium?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get headlineSmallItalic =>
      textTheme.headlineSmall?.copyWith(fontStyle: FontStyle.italic);

  // Title styles
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;

  TextStyle? get titleLargeBold =>
      textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get titleMediumBold =>
      textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get titleSmallBold =>
      textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get titleLargeItalic =>
      textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get titleMediumItalic =>
      textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get titleSmallItalic =>
      textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic);

  // Body styles
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;

  TextStyle? get bodyLargeBold =>
      textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get bodyMediumBold =>
      textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get bodySmallBold =>
      textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get bodyLargeItalic =>
      textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get bodyMediumItalic =>
      textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get bodySmallItalic =>
      textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic);

  // Secondary is a *text* role, so it maps to onSurfaceVariant. outline is the
  // border/divider role: using it for body copy lowers contrast below the
  // accessible secondary-text tone consumers styles assert against.
  TextStyle? get bodyLargeSecondary =>
      textTheme.bodyLarge?.withColor(onSurfaceVariantColor);
  TextStyle? get bodyMediumSecondary =>
      textTheme.bodyMedium?.withColor(onSurfaceVariantColor);
  TextStyle? get bodySmallSecondary =>
      textTheme.bodySmall?.withColor(onSurfaceVariantColor);

  TextStyle? get bodyLargeError => textTheme.bodyLarge?.withColor(errorColor);
  TextStyle? get bodyMediumError => textTheme.bodyMedium?.withColor(errorColor);
  TextStyle? get bodySmallError => textTheme.bodySmall?.withColor(errorColor);

  // Label styles
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;

  TextStyle? get labelLargeBold =>
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get labelMediumBold =>
      textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get labelSmallBold =>
      textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get labelLargeItalic =>
      textTheme.labelLarge?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get labelMediumItalic =>
      textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic);
  TextStyle? get labelSmallItalic =>
      textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic);

  TextStyle? get labelLargeSecondary =>
      textTheme.labelLarge?.withColor(onSurfaceVariantColor);
  TextStyle? get labelMediumSecondary =>
      textTheme.labelMedium?.withColor(onSurfaceVariantColor);
  TextStyle? get labelSmallSecondary =>
      textTheme.labelSmall?.withColor(onSurfaceVariantColor);

  TextStyle? get labelLargeError => textTheme.labelLarge?.withColor(errorColor);
  TextStyle? get labelMediumError =>
      textTheme.labelMedium?.withColor(errorColor);
  TextStyle? get labelSmallError => textTheme.labelSmall?.withColor(errorColor);
}
