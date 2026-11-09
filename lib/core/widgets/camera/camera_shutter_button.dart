import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

/// Molekul tombol shutter besar Material 3 Expressive.
class CameraShutterButton extends StatelessWidget {
  const CameraShutterButton({
    required this.canCapture,
    required this.isCapturing,
    required this.colorScheme,
    required this.onTap,
    this.isScreenFlashActive = false,
    super.key,
  });

  final bool canCapture;
  final bool isCapturing;
  final M3EColorScheme colorScheme;
  final VoidCallback onTap;
  final bool isScreenFlashActive;

  static const double _buttonSize = 72;
  static const double _strokeWidth = 4;

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = AppMotion.isReducedMotion(context);

    // Label aksesibilitas dinamis Material 3
    final String semanticLabel;
    if (isCapturing) {
      semanticLabel = 'Sedang memproses foto';
    } else {
      semanticLabel = 'Ambil foto';
    }

    return AppTappable.builder(
      key: const ValueKey<String>('camera_shutter_button'),
      onTap: canCapture ? onTap : null,
      enabled: canCapture,
      pressedScale: 1, // Pertahankan housing lingkar luar tetap stabil
      haptic: M3EHapticFeedback.medium,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final isPressed = state.pressed && canCapture;

        // Skala inti dalam: saat ditekan mengecil halus (0.88),
        // saat capturing/sibuk berada di 0.92, saat normal 1.0.
        final double coreScale;
        if (isReducedMotion) {
          coreScale = 1;
        } else if (isPressed) {
          coreScale = 0.88;
        } else if (isCapturing) {
          coreScale = 0.92;
        } else {
          coreScale = 1;
        }

        // Warna dasar bergantung pada state screen flash (inversi dark theme)
        final baseColor = isScreenFlashActive ? Colors.black : Colors.white;

        // Warna piringan inti dalam
        final Color coreColor;
        if (isCapturing) {
          coreColor = baseColor.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        } else if (canCapture) {
          coreColor = baseColor;
        } else {
          coreColor = baseColor.withValues(
            alpha: AppStateLayer.disabledContainerOpacity,
          );
        }

        // Warna lingkar luar (housing)
        final Color ringColor;
        if (canCapture) {
          ringColor = baseColor;
        } else {
          ringColor = baseColor.withValues(
            alpha: AppStateLayer.disabledOpacity,
          );
        }

        return SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Lingkar Luar (Housing Ring)
              AnimatedContainer(
                duration: isReducedMotion ? Duration.zero : AppDuration.short3,
                curve: AppEasing.standard,
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: _strokeWidth),
                ),
              ),

              // 2. Piringan Inti Shutter M3 Expressive
              AnimatedScale(
                scale: coreScale,
                duration: isReducedMotion ? Duration.zero : AppDuration.short3,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: isReducedMotion
                      ? Duration.zero
                      : AppDuration.short3,
                  curve: AppEasing.standard,
                  width: _buttonSize - 12,
                  height: _buttonSize - 12,
                  decoration: BoxDecoration(
                    color: coreColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
