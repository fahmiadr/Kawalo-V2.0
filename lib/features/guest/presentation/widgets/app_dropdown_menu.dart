import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Dropdown Menus
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Dropdown Menu components and types
// directly from package `material_3_expressive` without custom modifications.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EDropdownController,
        M3EDropdownFieldStyle,
        M3EDropdownItem,
        M3EDropdownItemStyle,
        M3EDropdownMenu,
        M3EDropdownMenuTheme,
        M3EDropdownPanelStyle;

/// Alias for [M3EDropdownMenu] to maintain standard project naming.
typedef AppDropdownMenu<T> = M3EDropdownMenu<T>;

/// Alias for [M3EDropdownItem] to maintain standard project naming.
typedef AppDropdownItem<T> = M3EDropdownItem<T>;

/// Alias for [M3EDropdownController] to maintain standard project naming.
typedef AppDropdownController<T> = M3EDropdownController<T>;

/// Alias for [M3EDropdownMenuTheme] to maintain standard project naming.
typedef AppDropdownMenuTheme = M3EDropdownMenuTheme;

/// Alias for [M3EDropdownFieldStyle] to maintain standard project naming.
typedef AppDropdownFieldStyle = M3EDropdownFieldStyle;

/// Alias for [M3EDropdownPanelStyle] to maintain standard project naming.
typedef AppDropdownPanelStyle = M3EDropdownPanelStyle;

/// Alias for [M3EDropdownItemStyle] to maintain standard project naming.
typedef AppDropdownItemStyle = M3EDropdownItemStyle;
