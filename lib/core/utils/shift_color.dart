import 'package:flutter/material.dart' show Color, HSVColor;

/// Parses a shift colour stored as `#RRGGBB` / `RRGGBB`, or `null` when the
/// value is empty or invalid.
///
/// Purple hues are dropped on purpose: the app never shows purple, and the
/// colour is free text chosen by the group admin.
Color? parseShiftColor(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final hex = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hex.length != 6) return null;
  final rgb = int.tryParse(hex, radix: 16);
  if (rgb == null) return null;

  final color = Color(0xFF000000 | rgb);
  final hsv = HSVColor.fromColor(color);
  final isPurple = hsv.saturation > 0.15 && hsv.hue >= 250 && hsv.hue <= 330;
  return isPurple ? null : color;
}
