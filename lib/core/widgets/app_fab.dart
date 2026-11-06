import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Floating Action Buttons
// ---------------------------------------------------------------------------
// Extends Material 3 Expressive FAB components with an additional `error` color
// variant and custom background / foreground color overrides.

export 'package:kawalo_mobile/core/widgets/app_fab_menu.dart';
export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EExtendedFab,
        M3EFab,
        M3EFabColor,
        M3EFabDecoration,
        M3EFabSize,
        M3EFabTheme;

/// The floating action button color variants, extending M3E with error color.
enum AppFabColor {
  /// Primary container colors.
  primary,

  /// Secondary container colors.
  secondary,

  /// Tertiary container colors.
  tertiary,

  /// Surface container colors.
  surface,

  /// Error container colors.
  error,
}

/// Alias for [M3EFabDecoration] to maintain standard project naming.
typedef AppFabDecoration = M3EFabDecoration;

/// Alias for [M3EFabSize] to maintain standard project naming.
typedef AppFabSize = M3EFabSize;

/// Alias for [M3EFabTheme] to maintain standard project naming.
typedef AppFabTheme = M3EFabTheme;

/// A Material 3 Expressive floating action button with extended color options.
///
/// Supports standard [AppFabColor] variants including [AppFabColor.error], as
/// well as custom [backgroundColor] and [foregroundColor] overrides.
class AppFab extends StatelessWidget {
  /// Creates an [AppFab].
  const AppFab({
    required this.icon,
    this.onPressed,
    this.size = AppFabSize.regular,
    this.color = AppFabColor.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.cornerRadius,
    this.decoration,
    this.elevation,
    this.hoverElevation,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  })  : assert(elevation == null || elevation >= 0.0, 'assertion failed'),
        assert(
          hoverElevation == null || hoverElevation >= 0.0,
          'assertion failed',
        );

  /// The icon widget displayed inside the button.
  final Widget icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The size variant of the FAB.
  final AppFabSize size;

  /// The color variant of the FAB.
  final AppFabColor color;

  /// Optional custom background color override.
  final Color? backgroundColor;

  /// Optional custom foreground (icon) color override.
  final Color? foregroundColor;

  /// When set, overrides the themed corner radius (e.g. for open/close morph).
  final double? cornerRadius;

  /// Optional decoration for solid and gradient surfaces.
  final AppFabDecoration? decoration;

  /// Resting surface elevation.
  final double? elevation;

  /// Surface elevation while hovered.
  final double? hoverElevation;

  /// Tooltip text displayed on hover or long press.
  final String? tooltip;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether this button should focus itself automatically.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = _resolveFabDecoration(
      context: context,
      color: color,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      decoration: decoration,
    );

    return M3EFab(
      icon: icon,
      onPressed: onPressed,
      size: size,
      color: _mapToM3EFabColor(color),
      cornerRadius: cornerRadius,
      decoration: effectiveDecoration,
      elevation: elevation,
      hoverElevation: hoverElevation,
      tooltip: tooltip,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// A Material 3 Expressive extended floating action button with extended color
/// options.
///
/// Supports standard [AppFabColor] variants including [AppFabColor.error], as
/// well as custom [backgroundColor] and [foregroundColor] overrides.
class AppExtendedFab extends StatelessWidget {
  /// Creates an [AppExtendedFab].
  const AppExtendedFab({
    required this.label,
    required this.icon,
    this.onPressed,
    this.color = AppFabColor.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.extended = true,
    this.decoration,
    this.elevation,
    this.hoverElevation,
    this.focusNode,
    this.autofocus = false,
    super.key,
  })  : assert(elevation == null || elevation >= 0.0, 'assertion failed'),
        assert(
          hoverElevation == null || hoverElevation >= 0.0,
          'assertion failed',
        );

  /// The text label displayed next to the icon.
  final String label;

  /// The icon widget displayed inside the button.
  final Widget icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The color variant of the FAB.
  final AppFabColor color;

  /// Optional custom background color override.
  final Color? backgroundColor;

  /// Optional custom foreground (label and icon) color override.
  final Color? foregroundColor;

  /// Whether the label is shown. When false the button collapses to the icon.
  final bool extended;

  /// Optional decoration for solid and gradient surfaces.
  final AppFabDecoration? decoration;

  /// Resting surface elevation.
  final double? elevation;

  /// Surface elevation while hovered.
  final double? hoverElevation;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether this button should focus itself automatically.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = _resolveFabDecoration(
      context: context,
      color: color,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      decoration: decoration,
    );

    return M3EExtendedFab(
      label: label,
      icon: icon,
      onPressed: onPressed,
      color: _mapToM3EFabColor(color),
      extended: extended,
      decoration: effectiveDecoration,
      elevation: elevation,
      hoverElevation: hoverElevation,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// Resolves effective [M3EFabDecoration] with custom colors or error role.
M3EFabDecoration? _resolveFabDecoration({
  required BuildContext context,
  required AppFabColor color,
  required Color? backgroundColor,
  required Color? foregroundColor,
  required AppFabDecoration? decoration,
}) {
  final colorScheme = AppTheme.colorSchemeOf(context);
  final errorBg =
      color == AppFabColor.error ? colorScheme.errorContainer : null;
  final errorFg =
      color == AppFabColor.error ? colorScheme.onErrorContainer : null;

  final effectiveBg = backgroundColor ?? errorBg;
  final effectiveFg = foregroundColor ?? errorFg;

  if (effectiveBg == null && effectiveFg == null) {
    return decoration;
  }

  return (decoration ?? const M3EFabDecoration()).copyWith(
    backgroundColor: effectiveBg != null
        ? WidgetStatePropertyAll<Color?>(effectiveBg)
        : decoration?.backgroundColor,
    foregroundColor: effectiveFg != null
        ? WidgetStatePropertyAll<Color?>(effectiveFg)
        : decoration?.foregroundColor,
  );
}

/// Maps [AppFabColor] to the underlying [M3EFabColor].
M3EFabColor _mapToM3EFabColor(AppFabColor color) {
  switch (color) {
    case AppFabColor.primary:
      return M3EFabColor.primary;
    case AppFabColor.secondary:
      return M3EFabColor.secondary;
    case AppFabColor.tertiary:
      return M3EFabColor.tertiary;
    case AppFabColor.surface:
      return M3EFabColor.surface;
    case AppFabColor.error:
      return M3EFabColor.primary;
  }
}

/// A stationary [FloatingActionButtonLocation] anchored at the end-float
/// position that remains completely fixed relative to the [Scaffold] viewport
/// and is NOT pushed, animated, or repositioned when the virtual keyboard
/// appears.
///
/// Automatically respects the [Scaffold] bottom navigation bar height if
/// present, or the system bottom safe area
/// ([ScaffoldPrelayoutGeometry.minViewPadding]) when [respectSafeArea] is true.
class AppStationaryEndFloatFabLocation extends FloatingActionButtonLocation {
  /// Creates an [AppStationaryEndFloatFabLocation].
  const AppStationaryEndFloatFabLocation({
    this.bottomOffset = 16.0,
    this.endOffset = 16.0,
    this.respectSafeArea = true,
  });

  /// The distance from the bottom edge of the [Scaffold] or safe area.
  final double bottomOffset;

  /// The distance from the end edge (right in LTR, left in RTL).
  final double endOffset;

  /// Whether to respect the system bottom safe area when no
  /// bottom navigation bar is present in the [Scaffold].
  final bool respectSafeArea;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX;
    if (scaffoldGeometry.textDirection == TextDirection.rtl) {
      fabX = endOffset;
    } else {
      fabX = scaffoldGeometry.scaffoldSize.width -
          scaffoldGeometry.floatingActionButtonSize.width -
          endOffset;
    }

    final safeAreaBottom =
        respectSafeArea ? scaffoldGeometry.minViewPadding.bottom : 0;
    final nonKeyboardBottomHeight = math.max(
      0,
      scaffoldGeometry.scaffoldSize.height -
          scaffoldGeometry.contentBottom -
          scaffoldGeometry.minInsets.bottom,
    );
    final baseBottomInset = math.max(
      safeAreaBottom,
      nonKeyboardBottomHeight,
    );

    final fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        baseBottomInset -
        bottomOffset;

    return Offset(fabX, fabY);
  }
}
