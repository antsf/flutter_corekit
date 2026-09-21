/// Hex-string <-> [Color] conversion helpers.
///
/// Complements [ColorContextExtensions] (which is about theme roles, not raw
/// hex parsing) and `FcColors` (which is a fixed palette, not user-supplied
/// hex input) — this is for the common case of accepting a hex color string
/// from an API response, CMS, or design tool and turning it into a [Color],
/// or serializing a [Color] back to a hex string for storage/display.
library;

import 'package:flutter/material.dart';

/// Extension methods on [String] to parse hex color strings into [Color].
extension ColorHexExt on String {
  /// Parses this string as a hex color into a [Color].
  ///
  /// Accepts an optional leading `#`, and either 6 digits (RGB, fully
  /// opaque) or 8 digits (AARRGGBB). Returns `null` instead of throwing if
  /// the string isn't a valid hex color, so callers can fall back to a
  /// default color for untrusted input (e.g. from an API or CMS).
  ///
  /// Examples:
  /// ```dart
  /// '#FF5733'.toColor();   // opaque orange
  /// 'FF5733'.toColor();    // same, '#' is optional
  /// '80FF5733'.toColor();  // ARGB with 0x80 alpha
  /// 'not-a-color'.toColor(); // null
  /// ```
  Color? toColor() {
    var hex = startsWith('#') ? substring(1) : this;
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;

    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;

    return Color(value);
  }
}

/// Extension methods on [Color] to serialize back to a hex string.
extension ColorToHexExt on Color {
  /// Returns this color as an `#AARRGGBB` hex string (uppercase, `#`-prefixed).
  ///
  /// Uses the modern floating-point channel getters ([Color.a], [Color.r],
  /// [Color.g], [Color.b], each `0.0`–`1.0`) rather than the deprecated
  /// 32-bit `.value`/`>> 24` bit-shifting approach, so it keeps working as
  /// Flutter moves color internals to wide-gamut floating point.
  ///
  /// Pass [includeAlpha] as `false` to omit the alpha channel and get a
  /// plain `#RRGGBB` string instead.
  String toHex({bool includeAlpha = true}) {
    String channel(double c) =>
        (c * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');

    final rgb = '${channel(r)}${channel(g)}${channel(b)}';
    return '#${includeAlpha ? '${channel(a)}$rgb' : rgb}'.toUpperCase();
  }
}
