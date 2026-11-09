import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_overlay_button_decoration.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_quota_badge.dart';

/// Molekul bar navigasi atas kamera (tutup, indikator kuota, flash).
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    required this.onClose,
    required this.totalPhotos,
    required this.maxPhotos,
    required this.flashMode,
    required this.deviceOrientation,
    required this.orientationTurns,
    required this.activeBadgeOrientation,
    required this.badgeFadeAnimation,
    required this.badgeScaleAnimation,
    this.onToggleFlash,
    this.isFlashSupported = true,
    this.topCutoutPadding = 0,
    this.hasError = false,
    super.key,
  });

  final VoidCallback onClose;
  final int totalPhotos;
  final int maxPhotos;
  final FlashMode flashMode;
  final DeviceOrientation deviceOrientation;
  final double orientationTurns;
  final DeviceOrientation activeBadgeOrientation;
  final Animation<double> badgeFadeAnimation;
  final Animation<double> badgeScaleAnimation;
  final VoidCallback? onToggleFlash;
  final bool isFlashSupported;
  final double topCutoutPadding;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final emphasizedTypeScale = AppTheme.emphasizedTypeScaleOf(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);
    final isTopBarBadgeActive = activeBadgeOrientation.isPortrait;
    final isPortraitDown =
        activeBadgeOrientation == DeviceOrientation.portraitDown;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top: topCutoutPadding + AppSpacing.space100,
        bottom: AppSpacing.space100,
        left: AppSpacing.space200,
        right: AppSpacing.space200,
      ),
      child: Row(
        children: [
          // Sayap Kiri: Tombol Batal/Tutup
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppIconButton(
                key: const ValueKey<String>('camera_close_button'),
                semanticLabel: 'Tutup kamera',
                onPressed: onClose,
                haptic: M3EHapticFeedback.light,
                decoration: M3EIconButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.scrim.withValues(alpha: 0.60),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(
                    Colors.white,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                icon: const AppSvgIcon(
                  KawaloVectors.cancel01,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Tengah: Badge Indikator Kuota Foto M3 Expressive Seimbang
          // (Zero-Layout Shift: Dimensi layout tetap dipertahankan meski
          // badge memudar keluar saat mode lanskap. Disembunyikan saat error).
          if (!hasError)
            FadeTransition(
              key: const ValueKey<String>('camera_quota_badge'),
              opacity: isTopBarBadgeActive
                  ? badgeFadeAnimation
                  : const AlwaysStoppedAnimation(0),
              child: ScaleTransition(
                scale: isTopBarBadgeActive
                    ? badgeScaleAnimation
                    : const AlwaysStoppedAnimation(1),
                child: IgnorePointer(
                  ignoring: !isTopBarBadgeActive,
                  child: RotatedBox(
                    quarterTurns: isPortraitDown ? 2 : 0,
                    child: CameraQuotaBadge(
                      totalPhotos: totalPhotos,
                      maxPhotos: maxPhotos,
                      colorScheme: colorScheme,
                      emphasizedTypeScale: emphasizedTypeScale,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          // Sayap Kanan: Kontrol Flash (atau slot kosong jika tidak didukung/error)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: (!hasError && isFlashSupported)
                  ? AppIconButton(
                      key: const ValueKey<String>('camera_flash_button'),
                      semanticLabel: _flashSemanticLabel(flashMode),
                      onPressed: onToggleFlash,
                      haptic: M3EHapticFeedback.light,
                      decoration: buildCameraOverlayButtonDecoration(
                        colorScheme: colorScheme,
                      ),
                      icon: AnimatedRotation(
                        turns: orientationTurns,
                        duration: isReducedMotion
                            ? Duration.zero
                            : AppMultiShotCameraScreen.rotationDuration,
                        curve: AppMultiShotCameraScreen.rotationCurve,
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            key: const ValueKey<String>(
                              'camera_flash_switcher',
                            ),
                            duration: isReducedMotion
                                ? Duration.zero
                                : AppDuration.medium2,
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic.flipped,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (child, animation) {
                              final isIncoming =
                                  child.key == ValueKey<FlashMode>(flashMode);
                              final inTween = Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              );
                              final outTween = Tween<Offset>(
                                begin: const Offset(0, -1),
                                end: Offset.zero,
                              );
                              final offsetAnimation =
                                  (isIncoming ? inTween : outTween)
                                      .animate(animation);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: AppSvgIcon(
                              key: ValueKey<FlashMode>(flashMode),
                              _flashIcon(flashMode),
                              color: _flashIconColor(
                                flashMode,
                                isEnabled: onToggleFlash != null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  static const Color _activeFlashAmber = Color(0xFFFFD54F);

  static Color _flashIconColor(
    FlashMode mode, {
    required bool isEnabled,
  }) {
    final isAmber = mode == FlashMode.always || mode == FlashMode.torch;
    final baseColor = isAmber ? _activeFlashAmber : Colors.white;
    if (!isEnabled) {
      return baseColor.withValues(alpha: AppStateLayer.disabledOpacity);
    }
    return baseColor;
  }

  static String _flashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return KawaloVectors.flashAuto;
      case FlashMode.always:
        return KawaloVectors.flash;
      case FlashMode.torch:
        return KawaloVectors.flashTorch;
      case FlashMode.off:
        return KawaloVectors.flashOff;
    }
  }

  static String _flashSemanticLabel(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return 'Lampu kilat otomatis';
      case FlashMode.always:
        return 'Lampu kilat selalu menyala saat foto';
      case FlashMode.torch:
        return 'Lampu senter terus menyala';
      case FlashMode.off:
        return 'Lampu kilat mati';
    }
  }
}
