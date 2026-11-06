import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive App Bars
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive App Bar components and types
// directly from package `material_3_expressive` without custom modifications.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EAppBar,
        M3EAppBarDensity,
        M3EAppBarShapeFamily,
        M3EAppBarTheme,
        M3EAppBarVariant;

export 'app_home_app_bar.dart';

/// Alias for [M3EAppBar] to maintain standard project naming.
typedef AppAppBar = M3EAppBar;

/// Alias for [M3EAppBarVariant] to maintain standard project naming.
typedef AppAppBarVariant = M3EAppBarVariant;

/// Alias for [M3EAppBarTheme] to maintain standard project naming.
typedef AppAppBarTheme = M3EAppBarTheme;
