import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';

/// Helper pembangun dekorasi tombol overlay translusen kamera Material 3
/// Expressive.
M3EIconButtonDecoration buildCameraOverlayButtonDecoration({
  required M3EColorScheme colorScheme,
  bool isScreenFlashActive = false,
}) {
  return M3EIconButtonDecoration(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (isScreenFlashActive) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.black.withValues(
            alpha: 0.12 * AppStateLayer.disabledContainerOpacity,
          );
        }
        return Colors.black.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.disabled)) {
        return colorScheme.scrim.withValues(
          alpha: 0.60 * AppStateLayer.disabledContainerOpacity,
        );
      }
      return colorScheme.scrim.withValues(alpha: 0.60);
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (isScreenFlashActive) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.black.withValues(alpha: AppStateLayer.disabledOpacity);
        }
        return Colors.black;
      }
      if (states.contains(WidgetState.disabled)) {
        return Colors.white.withValues(alpha: AppStateLayer.disabledOpacity);
      }
      return Colors.white;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (isScreenFlashActive) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: Colors.black.withValues(
              alpha: 0.20 * AppStateLayer.disabledOpacity,
            ),
          );
        }
        return BorderSide(color: Colors.black.withValues(alpha: 0.20));
      }
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(
          color: Colors.white.withValues(
            alpha: 0.30 * AppStateLayer.disabledOpacity,
          ),
        );
      }
      return BorderSide(color: Colors.white.withValues(alpha: 0.30));
    }),
  );
}
