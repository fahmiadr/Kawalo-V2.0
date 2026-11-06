import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Shapes Container
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive Shape Containers, clippers, and
// shape kinds directly from package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EMaterialNewShapes,
        M3EShapeClipper,
        M3EShapeContainer,
        M3EShapeKind,
        M3EShapes;

/// Alias for [M3EShapeContainer] to maintain standard project naming.
typedef AppShapeContainer = M3EShapeContainer;

/// Alias for [M3EShapeKind] to maintain standard project naming.
typedef AppShapeKind = M3EShapeKind;

/// Alias for [M3EShapeClipper] to maintain standard project naming.
typedef AppShapeClipper = M3EShapeClipper;
