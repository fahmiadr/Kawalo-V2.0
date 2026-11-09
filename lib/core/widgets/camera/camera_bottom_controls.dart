import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_overlay_button_decoration.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_shutter_button.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_thumbnail_tray.dart';

/// Organisme kontrol bawah (tombol selesai, baki thumbnail, shutter, switch).
class CameraBottomControls extends StatelessWidget {
  const CameraBottomControls({
    required this.capturedPhotos,
    required this.selectedPhotos,
    required this.scrollController,
    required this.isCapturing,
    required this.colorScheme,
    required this.hasMultipleCameras,
    required this.onTogglePhotoSelection,
    required this.onRemoveCapturedPhoto,
    required this.onTakePicture,
    required this.onDone,
    this.orientationTurns = 0,
    this.switchCameraTurns = 0,
    this.isScreenFlashActive = false,
    this.isCurrentCameraFront = false,
    this.onSwitchCamera,
    this.latestCapturedPath,
    this.removingPhotoPath,
    super.key,
  });

  final List<AppMediaFile> capturedPhotos;
  final List<AppMediaFile> selectedPhotos;
  final ScrollController scrollController;
  final String? latestCapturedPath;
  final String? removingPhotoPath;
  final bool isCapturing;
  final bool isScreenFlashActive;
  final bool isCurrentCameraFront;
  final M3EColorScheme colorScheme;
  final bool hasMultipleCameras;
  final double orientationTurns;
  final double switchCameraTurns;
  final VoidCallback? onSwitchCamera;
  final ValueChanged<AppMediaFile> onTogglePhotoSelection;
  final ValueChanged<int> onRemoveCapturedPhoto;
  final VoidCallback onTakePicture;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final canCapture = !isCapturing;
    final hasSelected = selectedPhotos.isNotEmpty;

    final isReducedMotion = AppMotion.isReducedMotion(context);
    final switchIconBaseColor = isScreenFlashActive
        ? Colors.black
        : Colors.white;
    final switchIconColor = onSwitchCamera != null
        ? switchIconBaseColor
        : switchIconBaseColor.withValues(alpha: AppStateLayer.disabledOpacity);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space200,
        bottom: AppSpacing.space200,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Baris Tombol Selesai & Baki Thumbnail ────────────────────
          // Berupa slot langsung tanpa animasi ekspansi vertikal
          // (AnimatedSize), sehingga elemen foto dan tombol selesai
          // langsung muncul di posisinya tanpa reflow melompat.
          if (capturedPhotos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space200,
              ),
              child: SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: isReducedMotion
                        ? Duration.zero
                        : AppDuration.medium2,
                    reverseDuration: isReducedMotion
                        ? Duration.zero
                        : AppDuration.short4,
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.80,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: hasSelected
                        ? AnimatedRotation(
                            turns: orientationTurns,
                            duration: isReducedMotion
                                ? Duration.zero
                                : AppMultiShotCameraScreen.rotationDuration,
                            curve: AppMultiShotCameraScreen.rotationCurve,
                            child: AppIconButton(
                              key: const ValueKey<String>('camera_done_button'),
                              variant: AppIconButtonColor.filled,
                              size: AppIconButtonSize.md,
                              semanticLabel:
                                  'Selesai mengambil foto '
                                  '(${selectedPhotos.length} '
                                  'foto dipilih)',
                              badgeValue: selectedPhotos.length,
                              badgeColor: colorScheme.surfaceContainerHigh,
                              badgeTextColor: colorScheme.onSurface,
                              haptic: M3EHapticFeedback.medium,
                              onPressed: onDone,
                              icon: AppSvgIcon(
                                KawaloVectors.check,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey<String>('empty_done_slot'),
                          ),
                  ),
                ),
              ),
            ),
            AppSpacing.vGap150,
            CameraThumbnailTray(
              photos: capturedPhotos,
              selectedPhotos: selectedPhotos,
              scrollController: scrollController,
              latestCapturedPath: latestCapturedPath,
              removingPhotoPath: removingPhotoPath,
              colorScheme: colorScheme,
              orientationTurns: orientationTurns,
              onToggleSelection: onTogglePhotoSelection,
              onRemovePhoto: onRemoveCapturedPhoto,
            ),
            AppSpacing.vGap200,
          ],

          // ── Baris Tombol Aksi Shutter & Switch Kamera Simetris ────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space200,
            ),
            child: Row(
              children: [
                // Sayap Kiri: Spacer penyeimbang simetri shutter
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 56, height: 56),
                  ),
                ),

                // Slot Tengah: Tombol Shutter Besar M3 Expressive
                CameraShutterButton(
                  canCapture: canCapture,
                  isCapturing: isCapturing,
                  colorScheme: colorScheme,
                  onTap: onTakePicture,
                  isScreenFlashActive: isScreenFlashActive,
                ),

                // Sayap Kanan: Tombol Switch Kamera Depan/Belakang
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: hasMultipleCameras
                        ? AppIconButton(
                            key: const ValueKey<String>('camera_switch_button'),
                            size: AppIconButtonSize.md,
                            semanticLabel: isCurrentCameraFront
                                ? 'Beralih ke kamera belakang'
                                : 'Beralih ke kamera depan',
                            onPressed: onSwitchCamera,
                            haptic: M3EHapticFeedback.light,
                            decoration: buildCameraOverlayButtonDecoration(
                              colorScheme: colorScheme,
                              isScreenFlashActive: isScreenFlashActive,
                            ),
                            icon: AnimatedRotation(
                              turns: orientationTurns + switchCameraTurns,
                              duration: isReducedMotion
                                  ? Duration.zero
                                  : AppMultiShotCameraScreen.rotationDuration,
                              curve: AppMultiShotCameraScreen.rotationCurve,
                              child: AppSvgIcon(
                                KawaloVectors.refreshCcwDot,
                                color: switchIconColor,
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey<String>('camera_switch_placeholder'),
                            width: 56,
                            height: 56,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
