import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Menus
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Menu components, popups, models,
// and themes directly from package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EMenu,
        M3EMenuAnchorBuilder,
        M3EMenuAnchorPosition,
        M3EMenuColorStyle,
        M3EMenuContent,
        M3EMenuDivider,
        M3EMenuEntry,
        M3EMenuGroup,
        M3EMenuItem,
        M3EMenuItemShape,
        M3EMenuNode,
        M3EMenuPopup,
        M3EMenuSubmenu,
        M3EMenuTheme,
        showM3EMenu;

/// Alias for [M3EMenu] to maintain standard project naming.
typedef AppMenu = M3EMenu;

/// Alias for [M3EMenuAnchorBuilder] to maintain standard project naming.
typedef AppMenuAnchorBuilder = M3EMenuAnchorBuilder;

/// Alias for [M3EMenuTheme] to maintain standard project naming.
typedef AppMenuTheme = M3EMenuTheme;

/// Alias for [M3EMenuItem] to maintain standard project naming.
typedef AppMenuItem = M3EMenuItem;

/// Alias for [M3EMenuEntry] to maintain standard project naming.
typedef AppMenuEntry = M3EMenuEntry;

/// Alias for [M3EMenuNode] to maintain standard project naming.
typedef AppMenuNode = M3EMenuNode;

/// Alias for [M3EMenuDivider] to maintain standard project naming.
typedef AppMenuDivider = M3EMenuDivider;

/// Alias for [M3EMenuGroup] to maintain standard project naming.
typedef AppMenuGroup = M3EMenuGroup;

/// Alias for [M3EMenuSubmenu] to maintain standard project naming.
typedef AppMenuSubmenu = M3EMenuSubmenu;

/// Alias for [M3EMenuAnchorPosition] to maintain standard project naming.
typedef AppMenuAnchorPosition = M3EMenuAnchorPosition;

/// Alias for [M3EMenuColorStyle] to maintain standard project naming.
typedef AppMenuColorStyle = M3EMenuColorStyle;

/// Alias for [M3EMenuItemShape] to maintain standard project naming.
typedef AppMenuItemShape = M3EMenuItemShape;

/// Shows an expressive Material 3 menu popup anchored to [anchor].
Future<T?> showAppMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required List<AppMenuNode> children,
  AppMenuAnchorPosition position = AppMenuAnchorPosition.bottomEnd,
  AppMenuColorStyle colorStyle = AppMenuColorStyle.standard,
  T? selectedValue,
  bool closeOnSelect = true,
  double? preferredWidth,
  FocusNode? callerFocusNode,
  AppMenuTheme? themeOverride,
}) {
  return showM3EMenu<T>(
    context: context,
    anchor: anchor,
    children: children,
    position: position,
    colorStyle: colorStyle,
    selectedValue: selectedValue,
    closeOnSelect: closeOnSelect,
    preferredWidth: preferredWidth,
    callerFocusNode: callerFocusNode,
    themeOverride: themeOverride,
  );
}
