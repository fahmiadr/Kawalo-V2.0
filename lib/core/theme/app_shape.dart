import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Shape Tokens
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Shape tokens directly from
// package `material_3_expressive`.

export 'package:kawalo_mobile/core/theme/app_radius.dart';
export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EShapeContainer, M3EShapeKind, M3EShapeSet, M3EShapes;

/// Comprehensive Material 3 Expressive Shape Token System.
///
/// Contains [OutlinedBorder] shape definitions and expressive shape sets
/// ([round], [square]) for shape morphing animations.
abstract final class AppShape {
  const AppShape._();

  // -------------------------------------------------------------------------
  // OutlinedBorder Shape Tokens (Symmetric)
  // -------------------------------------------------------------------------
  /// 0dp corner radius border.
  static const OutlinedBorder none = RoundedRectangleBorder();

  /// 4dp corner radius border (Extra Small).
  static const OutlinedBorder extraSmall = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraSmall,
  );

  /// 8dp corner radius border (Small).
  static const OutlinedBorder small = RoundedRectangleBorder(
    borderRadius: AppRadius.borderSmall,
  );

  /// 12dp corner radius border (Medium).
  static const OutlinedBorder medium = RoundedRectangleBorder(
    borderRadius: AppRadius.borderMedium,
  );

  /// 16dp corner radius border (Large).
  static const OutlinedBorder large = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLarge,
  );

  /// 20dp corner radius border (Large Increased).
  static const OutlinedBorder largeIncreased = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLargeIncreased,
  );

  /// 28dp corner radius border (Extra Large).
  static const OutlinedBorder extraLarge = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraLarge,
  );

  /// 32dp corner radius border (Extra Large Increased).
  static const OutlinedBorder extraLargeIncreased = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraLargeIncreased,
  );

  /// 48dp corner radius border (Extra Extra Large).
  static const OutlinedBorder extraExtraLarge = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraExtraLarge,
  );

  /// Fully rounded stadium border.
  static const OutlinedBorder full = StadiumBorder();

  // -------------------------------------------------------------------------
  // Directional & Asymmetric Shape Tokens
  // -------------------------------------------------------------------------
  /// Top corners rounded with Extra Small (4dp).
  static const OutlinedBorder extraSmallTop = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraSmallTop,
  );

  /// Top corners rounded with Large (16dp).
  static const OutlinedBorder largeTop = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLargeTop,
  );

  /// Top corners rounded with Extra Large (28dp).
  static const OutlinedBorder extraLargeTop = RoundedRectangleBorder(
    borderRadius: AppRadius.borderExtraLargeTop,
  );

  /// Start corners rounded with Large (16dp).
  static const OutlinedBorder largeStart = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLargeStart,
  );

  /// End corners rounded with Large (16dp).
  static const OutlinedBorder largeEnd = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLargeEnd,
  );

  // -------------------------------------------------------------------------
  // Expressive Shape Sets & Interpolation
  // -------------------------------------------------------------------------
  /// Expressive Round Shape Set.
  static const M3EShapeSet round = M3EShapes.roundSet;

  /// Expressive Square Shape Set.
  static const M3EShapeSet square = M3EShapes.squareSet;

  /// Interpolates between two shape borders for expressive shape morphing.
  static ShapeBorder? lerp(ShapeBorder? a, ShapeBorder? b, double t) {
    return ShapeBorder.lerp(a, b, t);
  }
}
