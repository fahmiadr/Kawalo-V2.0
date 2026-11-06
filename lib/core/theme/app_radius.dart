import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Radius Tokens
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Radius tokens directly from
// package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EShapes;

/// Comprehensive Material 3 Expressive Corner Radius Token System.
abstract final class AppRadius {
  const AppRadius._();

  // -------------------------------------------------------------------------
  // Scalar Corner Radius Values (dp)
  // -------------------------------------------------------------------------
  static const double none = M3EShapes.none; // 0dp
  static const double extraSmall = M3EShapes.extraSmall; // 4dp
  static const double xs = M3EShapes.extraSmall;
  static const double small = M3EShapes.small; // 8dp
  static const double sm = M3EShapes.small;
  static const double medium = M3EShapes.medium; // 12dp
  static const double md = M3EShapes.medium;
  static const double large = M3EShapes.large; // 16dp
  static const double lg = M3EShapes.large;
  static const double largeIncreased = M3EShapes.largeIncreased; // 20dp
  static const double lgIncreased = M3EShapes.largeIncreased;
  static const double extraLarge = M3EShapes.extraLarge; // 28dp
  static const double xl = M3EShapes.extraLarge;
  static const double extraLargeIncreased =
      M3EShapes.extraLargeIncreased; // 32dp
  static const double xlIncreased = M3EShapes.extraLargeIncreased;
  static const double extraExtraLarge = M3EShapes.extraExtraLarge; // 48dp
  static const double xxl = M3EShapes.extraExtraLarge;
  static const double full = M3EShapes.full;

  /// Ordered list of standard M3 corner radius tokens.
  static const List<double> values = [
    none,
    extraSmall,
    small,
    medium,
    large,
    largeIncreased,
    extraLarge,
    extraLargeIncreased,
    extraExtraLarge,
    full,
  ];

  // -------------------------------------------------------------------------
  // Radius Tokens
  // -------------------------------------------------------------------------
  static const Radius radiusNone = Radius.zero;
  static const Radius radiusExtraSmall = Radius.circular(M3EShapes.extraSmall);
  static const Radius radiusXs = radiusExtraSmall;
  static const Radius radiusSmall = Radius.circular(M3EShapes.small);
  static const Radius radiusSm = radiusSmall;
  static const Radius radiusMedium = Radius.circular(M3EShapes.medium);
  static const Radius radiusMd = radiusMedium;
  static const Radius radiusLarge = Radius.circular(M3EShapes.large);
  static const Radius radiusLg = radiusLarge;
  static const Radius radiusLargeIncreased =
      Radius.circular(M3EShapes.largeIncreased);
  static const Radius radiusLgIncreased = radiusLargeIncreased;
  static const Radius radiusExtraLarge = Radius.circular(M3EShapes.extraLarge);
  static const Radius radiusXl = radiusExtraLarge;
  static const Radius radiusExtraLargeIncreased =
      Radius.circular(M3EShapes.extraLargeIncreased);
  static const Radius radiusXlIncreased = radiusExtraLargeIncreased;
  static const Radius radiusExtraExtraLarge =
      Radius.circular(M3EShapes.extraExtraLarge);
  static const Radius radiusXxl = radiusExtraExtraLarge;
  static const Radius radiusFull = Radius.circular(M3EShapes.full);

  // -------------------------------------------------------------------------
  // BorderRadius Tokens (Symmetric)
  // -------------------------------------------------------------------------
  static const BorderRadius borderNone = BorderRadius.zero;
  static const BorderRadius borderExtraSmall =
      BorderRadius.all(radiusExtraSmall);
  static const BorderRadius borderSmall = BorderRadius.all(radiusSmall);
  static const BorderRadius borderMedium = BorderRadius.all(radiusMedium);
  static const BorderRadius borderLarge = BorderRadius.all(radiusLarge);
  static const BorderRadius borderLargeIncreased =
      BorderRadius.all(radiusLargeIncreased);
  static const BorderRadius borderExtraLarge =
      BorderRadius.all(radiusExtraLarge);
  static const BorderRadius borderExtraLargeIncreased =
      BorderRadius.all(radiusExtraLargeIncreased);
  static const BorderRadius borderExtraExtraLarge =
      BorderRadius.all(radiusExtraExtraLarge);
  static const BorderRadius borderFull = BorderRadius.all(radiusFull);

  // -------------------------------------------------------------------------
  // BorderRadius Tokens (Directional)
  // -------------------------------------------------------------------------
  static const BorderRadius borderExtraSmallTop =
      BorderRadius.vertical(top: radiusExtraSmall);
  static const BorderRadius borderLargeTop =
      BorderRadius.vertical(top: radiusLarge);
  static const BorderRadius borderExtraLargeTop =
      BorderRadius.vertical(top: radiusExtraLarge);
  static const BorderRadius borderLargeStart =
      BorderRadius.horizontal(left: radiusLarge);
  static const BorderRadius borderLargeEnd =
      BorderRadius.horizontal(right: radiusLarge);

  // -------------------------------------------------------------------------
  // Concentric Optical Roundness Calculations
  // -------------------------------------------------------------------------
  /// Snaps a numeric radius to the closest official M3 token value.
  static double snapToTokenValue(double value) {
    var closest = values.first;
    var minDiff = (value - closest).abs();
    for (final token in values) {
      final diff = (value - token).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = token;
      }
    }
    return closest;
  }

  /// Calculates optical roundness inner radius:
  /// `R_inner = max(0, R_outer - padding)`.
  ///
  /// If [snapToToken] is `true`, snaps the calculated value to the closest
  /// official Material 3 token.
  static double inner(
    double outerRadius,
    double padding, {
    bool snapToToken = false,
  }) {
    final result = outerRadius - padding;
    final raw = result > 0 ? result : 0.0;
    return snapToToken ? snapToTokenValue(raw) : raw;
  }

  /// Calculates concentric inner [BorderRadius] using [M3EShapes.resolve].
  ///
  /// If [snapToToken] is `true`, snaps the inner radius to the closest
  /// official Material 3 token.
  static BorderRadius innerBorder(
    double outerRadius,
    double padding, {
    bool snapToToken = false,
  }) {
    return M3EShapes.resolve(
      inner(outerRadius, padding, snapToToken: snapToToken),
    );
  }

  // -------------------------------------------------------------------------
  // Material 3 Expressive Dynamic Shape Morphing
  // -------------------------------------------------------------------------
  /// Menghitung kompresi [BorderRadius] untuk respon penekanan M3 Expressive.
  ///
  /// Sudut perimeter yang lebih besar atau sama dengan [AppRadius.medium]
  /// (12dp) akan dikompres sebesar [compression] (default 4dp, sehingga
  /// 12dp -> 8dp). Sudut persimpangan dalam (< 12dp, misalnya 4dp)
  /// tetap dipertahankan agar elemen yang terhubung tidak terlepas.
  static BorderRadius compressOnPress(
    BorderRadius resting, {
    double compression = 4.0,
  }) {
    double compressCorner(double r) =>
        r >= medium ? (r - compression).clamp(0.0, double.infinity) : r;
    return BorderRadius.only(
      topLeft: Radius.circular(compressCorner(resting.topLeft.x)),
      topRight: Radius.circular(compressCorner(resting.topRight.x)),
      bottomLeft: Radius.circular(compressCorner(resting.bottomLeft.x)),
      bottomRight: Radius.circular(compressCorner(resting.bottomRight.x)),
    );
  }

  /// Melakukan interpolasi linier antara [resting] dan [pressed] berdasarkan
  /// [progress] pegas (0.0 -> 1.0), dengan penjepitan nilai minimal 0.0
  /// untuk mencegah nilai negatif akibat pantulan pegas (*overshoot*).
  static BorderRadius lerpMorph(
    BorderRadius resting,
    BorderRadius pressed,
    double progress,
  ) {
    final interpolated =
        BorderRadius.lerp(resting, pressed, progress) ?? resting;
    return BorderRadius.only(
      topLeft: Radius.circular(
        interpolated.topLeft.x.clamp(0.0, double.infinity),
      ),
      topRight: Radius.circular(
        interpolated.topRight.x.clamp(0.0, double.infinity),
      ),
      bottomLeft: Radius.circular(
        interpolated.bottomLeft.x.clamp(0.0, double.infinity),
      ),
      bottomRight: Radius.circular(
        interpolated.bottomRight.x.clamp(0.0, double.infinity),
      ),
    );
  }
}
