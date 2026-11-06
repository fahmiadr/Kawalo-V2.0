import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Elevation Tokens
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Elevation tokens directly from
// package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EElevation;

/// Alias and token bridge for [M3EElevation].
abstract final class AppElevation {
  const AppElevation._();

  static const double level0 = M3EElevation.level0;
  static const double level1 = M3EElevation.level1;
  static const double level2 = M3EElevation.level2;
  static const double level3 = M3EElevation.level3;
  static const double level4 = M3EElevation.level4;
  static const double level5 = M3EElevation.level5;

  static const double scrimOpacity = 0.32;

  static List<BoxShadow> shadows(double elevation, {Color? shadowColor}) =>
      M3EElevation.shadows(elevation, shadowColor: shadowColor);

  static List<BoxShadow> get shadowLevel0 => shadows(level0);
  static List<BoxShadow> get shadowLevel1 => shadows(level1);
  static List<BoxShadow> get shadowLevel2 => shadows(level2);
  static List<BoxShadow> get shadowLevel3 => shadows(level3);
  static List<BoxShadow> get shadowLevel4 => shadows(level4);
  static List<BoxShadow> get shadowLevel5 => shadows(level5);
}
