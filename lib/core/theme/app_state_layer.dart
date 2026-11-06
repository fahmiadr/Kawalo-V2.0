import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive State Layer Tokens
// ---------------------------------------------------------------------------
// Re-exports pure Material 3 Expressive State Layer tokens directly from
// package `material_3_expressive`.

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EInteractionState,
        M3EStateLayer,
        M3EStateLayerOverlay,
        M3EStateOpacity;

/// Comprehensive Material 3 Expressive State Layer Token System.
abstract final class AppStateLayer {
  const AppStateLayer._();

  /// Hover state-layer opacity (8%).
  static const double hoverOpacity = M3EStateOpacity.hover;

  /// Focus state-layer opacity (10%).
  static const double focusOpacity = M3EStateOpacity.focus;

  /// Pressed state-layer opacity (10%).
  static const double pressedOpacity = M3EStateOpacity.pressed;

  /// Dragged state-layer opacity (16%).
  static const double draggedOpacity = M3EStateOpacity.dragged;

  /// Opacity applied to content (icon/label) of a disabled component (38%).
  static const double disabledOpacity = M3EStateOpacity.disabledContent;

  /// Opacity applied to container/surface of a disabled component (12%).
  static const double disabledContainerOpacity =
      M3EStateOpacity.disabledContainer;

  /// Minimum accessible touch target (48dp).
  static const double minTouchTarget = 48;
}
