import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Motion Tokens
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Motion tokens directly from
// package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EMotion, M3ESpring;

/// Alias for [M3EMotion] to provide duration tokens.
typedef AppDuration = M3EMotion;

/// Alias for [M3EMotion] to provide easing curve tokens.
typedef AppEasing = M3EMotion;

/// Comprehensive Material 3 Expressive Motion & Animation System.
abstract final class AppMotion {
  const AppMotion._();

  /// Checks if reduced motion preference is enabled in the current environment.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  // -------------------------------------------------------------------------
  // Duration Tokens (50ms - 1000ms)
  // -------------------------------------------------------------------------
  static const Duration short1 = M3EMotion.short1;
  static const Duration short2 = M3EMotion.short2;
  static const Duration short3 = M3EMotion.short3;
  static const Duration short4 = M3EMotion.short4;
  static const Duration medium1 = M3EMotion.medium1;
  static const Duration medium2 = M3EMotion.medium2;
  static const Duration medium3 = M3EMotion.medium3;
  static const Duration medium4 = M3EMotion.medium4;
  static const Duration long1 = M3EMotion.long1;
  static const Duration long2 = M3EMotion.long2;
  static const Duration long3 = M3EMotion.long3;
  static const Duration long4 = M3EMotion.long4;
  static const Duration extraLong1 = M3EMotion.extraLong1;
  static const Duration extraLong2 = M3EMotion.extraLong2;
  static const Duration extraLong3 = M3EMotion.extraLong3;
  static const Duration extraLong4 = M3EMotion.extraLong4;

  // Duration aliases (prefixed)
  static const Duration durationShort1 = short1;
  static const Duration durationShort2 = short2;
  static const Duration durationShort3 = short3;
  static const Duration durationShort4 = short4;
  static const Duration durationMedium1 = medium1;
  static const Duration durationMedium2 = medium2;
  static const Duration durationMedium3 = medium3;
  static const Duration durationMedium4 = medium4;
  static const Duration durationLong1 = long1;
  static const Duration durationLong2 = long2;
  static const Duration durationLong3 = long3;
  static const Duration durationLong4 = long4;
  static const Duration durationExtraLong1 = extraLong1;
  static const Duration durationExtraLong2 = extraLong2;
  static const Duration durationExtraLong3 = extraLong3;
  static const Duration durationExtraLong4 = extraLong4;

  // -------------------------------------------------------------------------
  // Easing Curves (Standard & Emphasized)
  // -------------------------------------------------------------------------
  static const Curve standard = M3EMotion.standard;
  static const Curve standardAccelerate = M3EMotion.standardAccelerate;
  static const Curve standardDecelerate = M3EMotion.standardDecelerate;
  static const Curve emphasized = M3EMotion.emphasized;
  static const Curve emphasizedAccelerate = M3EMotion.emphasizedAccelerate;
  static const Curve emphasizedDecelerate = M3EMotion.emphasizedDecelerate;
  static const Curve linear = M3EMotion.linear;

  // -------------------------------------------------------------------------
  // Standard Spatial Springs (Critically Damped, No Overshoot)
  // -------------------------------------------------------------------------
  /// Fast spatial spring for small bounds/position updates
  /// (stiffness: 1400, damping: 0.9).
  static const M3ESpring spatialFast = M3EMotion.spatialFast;

  /// Default spatial spring for general spatial movements
  /// (stiffness: 700, damping: 0.9).
  static const M3ESpring spatialDefault = M3EMotion.spatialDefault;

  /// Slow spatial spring for large movement/transitions
  /// (stiffness: 300, damping: 0.9).
  static const M3ESpring spatialSlow = M3EMotion.spatialSlow;

  /// AOSP spatial spring (stiffness: 380, damping: 1.0) with zero overshoot.
  static const M3ESpring aospSpatial = M3EMotion.aospSpatial;

  // -------------------------------------------------------------------------
  // Expressive Spatial Springs (Underdamped with Physical Overshoot)
  // -------------------------------------------------------------------------
  /// Fast expressive spring with dynamic overshoot
  /// (stiffness: 800, damping: 0.6).
  static const M3ESpring expressiveSpatialFast =
      M3EMotion.expressiveSpatialFast;

  /// Default expressive spring for prominent animations
  /// (stiffness: 380, damping: 0.8).
  static const M3ESpring expressiveSpatialDefault =
      M3EMotion.expressiveSpatialDefault;

  /// Expressive interactive press feedback spring
  /// (stiffness: 380, damping: 0.55).
  static const M3ESpring expressiveSpatialPress =
      M3EMotion.expressiveSpatialPress;

  /// Slow expressive spring for expansive morphs
  /// (stiffness: 300, damping: 1.0).
  static const M3ESpring expressiveSpatialSlow =
      M3EMotion.expressiveSpatialSlow;

  // -------------------------------------------------------------------------
  // Effects Springs (Color, Tint & Opacity Transitions - Zero Overshoot)
  // -------------------------------------------------------------------------
  /// Fast effects spring (stiffness: 3800, damping: 1.0).
  static const M3ESpring effectsFast = M3EMotion.effectsFast;

  /// Default effects spring (stiffness: 1600, damping: 1.0).
  static const M3ESpring effectsDefault = M3EMotion.effectsDefault;

  /// Slow effects spring (stiffness: 800, damping: 1.0).
  static const M3ESpring effectsSlow = M3EMotion.effectsSlow;

  // -------------------------------------------------------------------------
  // Spring Simulation Helpers
  // -------------------------------------------------------------------------
  /// Creates a [SpringSimulation] using the specified [M3ESpring] token.
  static SpringSimulation createSimulation(
    M3ESpring spring, {
    required double start,
    required double end,
    double velocity = 0.0,
    double mass = 1.0,
  }) {
    return spring.createSimulation(
      start: start,
      end: end,
      velocity: velocity,
      mass: mass,
    );
  }
}

/// Extension methods on [M3ESpring] for easy simulation creation.
extension AppM3ESpringX on M3ESpring {
  /// Converts [M3ESpring] to Flutter's [SpringDescription].
  SpringDescription toSpringDescription({double mass = 1.0}) {
    return SpringDescription.withDampingRatio(
      mass: mass,
      stiffness: stiffness,
      ratio: damping,
    );
  }

  /// Creates a [SpringSimulation] from this spring specification.
  SpringSimulation createSimulation({
    required double start,
    required double end,
    double velocity = 0.0,
    double mass = 1.0,
  }) {
    return SpringSimulation(
      toSpringDescription(mass: mass),
      start,
      end,
      velocity,
    );
  }
}
