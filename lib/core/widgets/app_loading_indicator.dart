import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Loading Indicator
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Loading Indicator components and types
// directly from package `material_3_expressive` while providing design system
// size variants and tokens.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EExpressiveLoadingIndicator,
        M3ELoadingIndicator,
        M3ELoadingIndicatorTheme,
        M3ELoadingIndicatorVariant;

/// Visual size variants for [AppLoadingIndicator].
enum AppLoadingIndicatorSize {
  /// Compact size (36x36dp container, 28dp active shape).
  small(containerSize: 36, activeSize: 28),

  /// Standard medium size (48x48dp container, 38dp active shape).
  medium(containerSize: 48, activeSize: 38),

  /// Prominent large size (64x64dp container, 50dp active shape).
  large(containerSize: 64, activeSize: 50),

  /// Extra large prominent size (72x72dp container, 56dp active shape).
  extraLarge(containerSize: 72, activeSize: 56);

  const AppLoadingIndicatorSize({
    required this.containerSize,
    required this.activeSize,
  });

  /// Outer container width and height in logical pixels.
  final double containerSize;

  /// Inner morphing shape width and height in logical pixels.
  final double activeSize;
}

/// Project-wide Material 3 Expressive Loading Indicator supporting
/// design system size tokens ([AppLoadingIndicatorSize]).
class AppLoadingIndicator extends StatelessWidget {
  /// Creates an [AppLoadingIndicator].
  const AppLoadingIndicator({
    super.key,
    this.variant = AppLoadingIndicatorVariant.defaultStyle,
    this.size = AppLoadingIndicatorSize.medium,
    this.color,
    this.containerColor,
    this.elevation,
    this.polygons,
    this.constraints,
    this.padding,
    this.globalRotationDuration,
    this.morphInterval,
    this.morphRotationDegrees,
    this.morphSpring,
    this.morphSpringVelocity,
    this.pulseStartScale,
    this.pulseSpring,
    this.pulseSpringVelocity,
    this.rotationTurns,
    this.semanticLabel,
    this.semanticValue,
  }) : assert(elevation == null || elevation >= 0.0, 'assertion failed');

  /// Loading indicator visual variant (defaultStyle or contained).
  final AppLoadingIndicatorVariant variant;

  /// Visual size token defining container and shape dimensions.
  final AppLoadingIndicatorSize size;

  /// Morphing shape (inner) color.
  final Color? color;

  /// Contained shell color behind the shape.
  final Color? containerColor;

  /// Surface elevation.
  final double? elevation;

  /// Sequence of polygon shapes to morph between.
  final List<RoundedPolygon>? polygons;

  /// Custom box constraints overriding default size constraints.
  final BoxConstraints? constraints;

  /// Padding surrounding the indicator.
  final EdgeInsetsGeometry? padding;

  /// Full 360-degree continuous spin period.
  final Duration? globalRotationDuration;

  /// Delay between polygon morph cycles.
  final Duration? morphInterval;

  /// Extra rotation degrees across each morph transition.
  final double? morphRotationDegrees;

  /// Spring driving morph progress.
  final M3ESpring? morphSpring;

  /// Initial velocity for the morph spring.
  final double? morphSpringVelocity;

  /// Scale at the start of each morph-in pulse.
  final double? pulseStartScale;

  /// Spring for the morph-in scale pulse settle.
  final M3ESpring? pulseSpring;

  /// Initial pulse spring velocity.
  final double? pulseSpringVelocity;

  /// Optional manual rotation turns.
  final double? rotationTurns;

  /// Accessibility label announced by screen readers.
  final String? semanticLabel;

  /// Accessibility value announced by screen readers.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final m3eTheme =
        M3ETheme.maybeOf(context) ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.m3eDark()
            : AppTheme.m3eLight());

    final currentLoadingTheme = m3eTheme.loadingIndicatorTheme;
    final targetTheme = m3eTheme.copyWith(
      loadingIndicatorTheme: currentLoadingTheme.copyWith(
        containerWidth: size.containerSize,
        containerHeight: size.containerSize,
        activeIndicatorSize: size.activeSize,
      ),
    );

    final indicator = M3ELoadingIndicator(
      variant: variant,
      color: color,
      containerColor: containerColor,
      polygons: polygons,
      constraints:
          constraints ??
          BoxConstraints.tight(Size(size.containerSize, size.containerSize)),
      padding: padding,
      globalRotationDuration: globalRotationDuration,
      morphInterval: morphInterval,
      morphRotationDegrees: morphRotationDegrees,
      morphSpring: morphSpring,
      morphSpringVelocity: morphSpringVelocity,
      pulseStartScale: pulseStartScale,
      pulseSpring: pulseSpring,
      pulseSpringVelocity: pulseSpringVelocity,
      rotationTurns: rotationTurns,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
    );

    return M3ETheme(
      data: targetTheme,
      child: elevation != null && elevation! > 0.0
          ? Material(
              type: MaterialType.transparency,
              elevation: elevation!,
              child: indicator,
            )
          : indicator,
    );
  }
}

/// Alias for [M3ELoadingIndicatorVariant] to maintain standard project naming.
typedef AppLoadingIndicatorVariant = M3ELoadingIndicatorVariant;

/// Alias for [M3ELoadingIndicatorTheme] to maintain standard project naming.
typedef AppLoadingIndicatorTheme = M3ELoadingIndicatorTheme;
