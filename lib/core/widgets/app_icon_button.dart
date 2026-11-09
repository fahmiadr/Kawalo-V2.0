import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Icon Buttons
// ---------------------------------------------------------------------------

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EHapticFeedback,
        M3EIconButton,
        M3EIconButtonDecoration,
        M3EIconButtonShapeVariant,
        M3EIconButtonSize,
        M3EIconButtonTheme,
        M3EIconButtonVariant,
        M3EIconButtonWidth;

/// Alias for [M3EIconButtonVariant] to maintain standard project naming.
typedef AppIconButtonColor = M3EIconButtonVariant;

/// Alias for [M3EIconButtonSize] to maintain standard project naming.
typedef AppIconButtonSize = M3EIconButtonSize;

/// Alias for [M3EIconButtonShapeVariant] to maintain standard project naming.
typedef AppIconButtonShape = M3EIconButtonShapeVariant;

/// Alias for [M3EIconButtonWidth] to maintain standard project naming.
typedef AppIconButtonWidth = M3EIconButtonWidth;

/// Material 3 Expressive Icon Button with robust badge hit-testing support.
///
/// Wraps [M3EIconButton] to maintain full M3 Expressive physics, morphing,
/// state layers, and token styling, while ensuring that [badgeValue] is
/// protected with [IgnorePointer] and [ExcludeSemantics] so it never blocks
/// button taps or pollutes the accessibility tree.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    super.key,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.variant = AppIconButtonColor.standard,
    this.size = AppIconButtonSize.sm,
    this.shape = AppIconButtonShape.round,
    this.width = AppIconButtonWidth.defaultWidth,
    this.isSelected,
    this.selectedIcon,
    this.enableFeedback,
    this.haptic = M3EHapticFeedback.none,
    this.badgeValue,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeOffset,
    this.suppressInk = false,
    this.visualSize,
    this.decoration,
  });

  /// The primary icon widget displayed within the button.
  final Widget icon;

  /// Callback executed when the button is tapped.
  final VoidCallback? onPressed;

  /// Optional tooltip text displayed on long press or hover.
  final String? tooltip;

  /// Accessibility label describing the action for assistive technology.
  final String? semanticLabel;

  /// Visual styling variant (standard, filled, tonal, outlined).
  final AppIconButtonColor variant;

  /// Size tier (sm: 40dp, md: 48dp, lg: 56dp).
  final AppIconButtonSize size;

  /// Shape geometry variant (round, square).
  final AppIconButtonShape shape;

  /// Width variant (defaultWidth, narrow, wide).
  final AppIconButtonWidth width;

  /// Optional toggle selection state.
  final bool? isSelected;

  /// Icon shown when [isSelected] is true.
  final Widget? selectedIcon;

  /// Whether auditory or haptic feedback is enabled.
  final bool? enableFeedback;

  /// Haptic intensity feedback mode.
  final M3EHapticFeedback haptic;

  /// Numeric or string value to display within the anchored badge.
  final Object? badgeValue;

  /// Custom background color for the badge container.
  final Color? badgeColor;

  /// Custom text/icon color for the badge content.
  final Color? badgeTextColor;

  /// Optional custom position offset for the badge.
  ///
  /// If null, default positioning follows official Material Design 3 rules:
  /// - For [AppIconButtonColor.standard] (transparent container): anchored to
  ///   the top-right corner of the central icon.
  /// - For container variants (filled, tonal, outlined): anchored to the
  ///   top-right corner of the button's surface container (`top: 0`, `end: 0`).
  final Offset? badgeOffset;

  /// When true, suppresses splash/hover ink effects.
  final bool suppressInk;

  /// Overrides theme visual size when non-null.
  final Size? visualSize;

  /// Optional custom surface decoration.
  final M3EIconButtonDecoration? decoration;

  Widget? _buildBadge(BuildContext context) {
    final v = badgeValue;
    if (v == null) {
      return null;
    }
    if (v is bool && !v) {
      return null;
    }
    if (v is String && v.isEmpty) {
      return null;
    }

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveBg = badgeColor ?? colorScheme.error;
    final effectiveFg = badgeTextColor ?? colorScheme.onError;

    if (v is bool && v) {
      return IgnorePointer(
        child: ExcludeSemantics(
          child: Badge(smallSize: 8, backgroundColor: effectiveBg),
        ),
      );
    }

    final String labelText;
    if (v is num) {
      final count = v.round();
      labelText = count > 99 ? '99+' : count.toString();
    } else {
      labelText = v.toString();
    }

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Badge(
          label: Text(labelText),
          backgroundColor: effectiveBg,
          textColor: effectiveFg,
        ),
      ),
    );
  }

  Offset _resolveDefaultBadgeOffset() {
    // According to official Material Design 3 guidelines:
    // 1. Standard (transparent) buttons anchor badges to the top-right
    //    corner of the central icon glyph.
    // 2. Filled, tonal, and outlined buttons anchor badges to the top-right
    //    corner of the button's visible container shape (top: 0, end: 0).
    if (variant != AppIconButtonColor.standard) {
      return Offset.zero;
    }

    final isDot = badgeValue is bool;
    final currentIcon = icon;
    final double iconDimension;
    if (currentIcon is Icon && currentIcon.size != null) {
      iconDimension = currentIcon.size!;
    } else if (currentIcon is AppSvgIcon && currentIcon.size != null) {
      iconDimension = currentIcon.size!;
    } else {
      iconDimension = switch (size) {
        AppIconButtonSize.xs => 20.0,
        AppIconButtonSize.sm || AppIconButtonSize.md => 24.0,
        AppIconButtonSize.lg => 32.0,
        AppIconButtonSize.xl => 40.0,
      };
    }

    final targetDimension =
        visualSize?.width ??
        switch (size) {
          AppIconButtonSize.xs || AppIconButtonSize.sm => 48.0,
          AppIconButtonSize.md => 56.0,
          AppIconButtonSize.lg => 96.0,
          AppIconButtonSize.xl => 136.0,
        };

    final inset = (targetDimension - iconDimension) / 2;
    if (isDot) {
      // Dot badge (diameter 8dp, radius 4dp) centered on the icon's top-right.
      final dotInset = (inset - 4.0).clamp(0.0, double.infinity);
      return Offset(dotInset, dotInset);
    } else {
      // Value badge (default height 16dp) anchored to icon's top-right:
      // - Center aligns with icon top edge (inset - 8dp).
      // - Right edge extends 4dp beyond icon right edge (inset - 4dp).
      final topOffset = (inset - 8.0).clamp(0.0, double.infinity);
      final endOffset = (inset - 4.0).clamp(0.0, double.infinity);
      return Offset(endOffset, topOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = M3EIconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      variant: variant,
      size: size,
      shape: shape,
      width: width,
      isSelected: isSelected,
      selectedIcon: selectedIcon,
      enableFeedback: enableFeedback,
      haptic: haptic,
      // Note: badgeValue is intentionally not passed to M3EIconButton because
      // its internal _wrapWithBadge lacks IgnorePointer, which intercepts
      // touches and blocks button taps.
      suppressInk: suppressInk,
      visualSize: visualSize,
      decoration: decoration,
    );

    final badgeWidget = _buildBadge(context);
    if (badgeWidget == null) {
      return button;
    }

    final defaultOffset = _resolveDefaultBadgeOffset();
    final effectiveTop = badgeOffset?.dy ?? defaultOffset.dy;
    final effectiveEnd = badgeOffset?.dx ?? defaultOffset.dx;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(
          top: effectiveTop,
          end: effectiveEnd,
          child: badgeWidget,
        ),
      ],
    );
  }
}
