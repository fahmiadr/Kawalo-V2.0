import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive FAB Menu
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive FAB Menu components, tokens, and types
// with full design token integration and extended color support.

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EFabMenu, M3EFabMenuItem, M3EFabMenuPosition, M3EFabMenuTheme;

/// Alias for [M3EFabMenuItem] to maintain standard project naming.
typedef AppFabMenuItem = M3EFabMenuItem;

/// Alias for [M3EFabMenuPosition] to maintain standard project naming.
typedef AppFabMenuPosition = M3EFabMenuPosition;

/// Alias for [M3EFabMenuTheme] to maintain standard project naming.
typedef AppFabMenuTheme = M3EFabMenuTheme;

/// A Material 3 Expressive FAB Menu that expands a list of quick action pills.
///
/// Supports standard [AppFabColor] variants (including [AppFabColor.error]) as
/// well as custom [backgroundColor] and [foregroundColor] overrides.
class AppFabMenu extends StatelessWidget {
  /// Creates an [AppFabMenu].
  const AppFabMenu({
    required this.items,
    this.size = AppFabSize.medium,
    this.color = AppFabColor.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.position = AppFabMenuPosition.right,
    this.expandIcon,
    this.collapseIcon,
    this.decoration,
    super.key,
  });

  /// The menu actions displayed when the menu opens.
  final List<AppFabMenuItem> items;

  /// Size of the closed and open FAB anchor.
  final AppFabSize size;

  /// Color palette of the FAB anchor.
  final AppFabColor color;

  /// Optional custom background color override for the anchor.
  final Color? backgroundColor;

  /// Optional custom foreground color override for the anchor.
  final Color? foregroundColor;

  /// Corner of the screen the FAB menu expands from.
  final AppFabMenuPosition position;

  /// Icon shown while the menu is closed.
  final Widget? expandIcon;

  /// Icon shown while the menu is open.
  final Widget? collapseIcon;

  /// Decoration overrides for the anchor FAB.
  final AppFabDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final errorBg = color == AppFabColor.error
        ? colorScheme.errorContainer
        : null;
    final errorFg = color == AppFabColor.error
        ? colorScheme.onErrorContainer
        : null;

    final effectiveBg = backgroundColor ?? errorBg;
    final effectiveFg = foregroundColor ?? errorFg;

    var effectiveDecoration = decoration;
    if (effectiveBg != null || effectiveFg != null) {
      effectiveDecoration = (decoration ?? const AppFabDecoration()).copyWith(
        backgroundColor: effectiveBg != null
            ? WidgetStatePropertyAll<Color?>(effectiveBg)
            : decoration?.backgroundColor,
        foregroundColor: effectiveFg != null
            ? WidgetStatePropertyAll<Color?>(effectiveFg)
            : decoration?.foregroundColor,
      );
    }

    return M3EFabMenu(
      items: items,
      size: size,
      color: _mapToM3EFabColor(color),
      position: position,
      expandIcon: expandIcon,
      collapseIcon: collapseIcon,
      decoration: effectiveDecoration,
    );
  }

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
}
