import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';

/// Molekul baki thumbnail foto yang ditangkap pada sesi berjalan.
class CameraThumbnailTray extends StatelessWidget {
  const CameraThumbnailTray({
    required this.photos,
    required this.selectedPhotos,
    required this.scrollController,
    required this.colorScheme,
    required this.onToggleSelection,
    required this.onRemovePhoto,
    this.orientationTurns = 0,
    this.latestCapturedPath,
    this.removingPhotoPath,
    super.key,
  });

  final List<AppMediaFile> photos;
  final List<AppMediaFile> selectedPhotos;
  final ScrollController scrollController;
  final String? latestCapturedPath;
  final String? removingPhotoPath;
  final M3EColorScheme colorScheme;
  final double orientationTurns;
  final ValueChanged<AppMediaFile> onToggleSelection;
  final ValueChanged<int> onRemovePhoto;

  static const double _thumbnailSize = 72;
  static const double _deleteButtonSize = 20;
  static const double _deleteButtonOffset = _deleteButtonSize / 4;
  static const double _itemSize = _thumbnailSize + _deleteButtonOffset;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isReducedMotion = AppMotion.isReducedMotion(context);

    return RepaintBoundary(
      child: SizedBox(
        height: _itemSize,
        child: ListView.separated(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space300),
          itemCount: photos.length,
          separatorBuilder: (context, sepIndex) {
            // Animasi masuk separator baru (0 -> 8dp) saat foto terbaru masuk
            final isFirstSepNewest =
                sepIndex == 0 &&
                photos.isNotEmpty &&
                photos.first.path != null &&
                photos.first.path == latestCapturedPath;
            if (isFirstSepNewest && !isReducedMotion) {
              return TweenAnimationBuilder<double>(
                key: ValueKey<String>('tray_sep_${photos.first.path}'),
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppDuration.medium2,
                curve: AppMotion.emphasized,
                builder: (_, val, _) =>
                    SizedBox(width: AppSpacing.space100 * val),
              );
            }

            // Animasi keluar separator (8dp -> 0) saat foto di sampingnya
            // sedang dihapus (collapse horizontal mulus)
            if (removingPhotoPath != null && !isReducedMotion) {
              final isAdjacentToRemoving =
                  (sepIndex < photos.length &&
                      photos[sepIndex].path == removingPhotoPath) ||
                  (sepIndex + 1 < photos.length &&
                      photos[sepIndex + 1].path == removingPhotoPath);
              if (isAdjacentToRemoving) {
                return TweenAnimationBuilder<double>(
                  key: ValueKey<String>('tray_sep_removing_$removingPhotoPath'),
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: AppDuration.short4,
                  curve: Curves.easeInCubic,
                  builder: (_, val, _) =>
                      SizedBox(width: AppSpacing.space100 * val),
                );
              }
            }

            return AppSpacing.hGap100;
          },
          itemBuilder: (context, index) {
            final photo = photos[index];
            final isSelected = selectedPhotos.contains(photo);
            final selectionIndex = isSelected
                ? selectedPhotos.indexOf(photo)
                : -1;
            final isNewest =
                photo.path != null &&
                photo.path == latestCapturedPath &&
                index == 0;
            final photoKey = photo.path ?? '$index';

            final cardWidget = RepaintBoundary(
              child: SizedBox(
                key: ValueKey<String>('tray_item_$photoKey'),
                width: _itemSize,
                height: _itemSize,
                child: AnimatedRotation(
                  turns: orientationTurns,
                  duration: isReducedMotion
                      ? Duration.zero
                      : AppMultiShotCameraScreen.rotationDuration,
                  curve: AppMultiShotCameraScreen.rotationCurve,
                  alignment: const Alignment(-5 / 77, 5 / 77),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Kartu Thumbnail 1:1 Murni (Bebas dari tombol hapus)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        width: _thumbnailSize,
                        height: _thumbnailSize,
                        child: AppMorphingSurface(
                          key: ValueKey<String>('captured_thumbnail_$photoKey'),
                          onTap: () => onToggleSelection(photo),
                          border: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          semanticLabel: isSelected
                              ? 'Foto ke-${index + 1} terpilih '
                                    '(urutan ke-${selectionIndex + 1})'
                              : 'Pilih foto ke-${index + 1}',
                          overlay: IgnorePointer(
                            child: AnimatedSwitcher(
                              duration: isReducedMotion
                                  ? Duration.zero
                                  : AppDuration.short4,
                              reverseDuration: isReducedMotion
                                  ? Duration.zero
                                  : AppDuration.short3,
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
                              child: isSelected
                                  ? Center(
                                      key: ValueKey<String>(
                                        'selected_${photo.path}_'
                                        '$selectionIndex',
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          // Ikon centang putih di tengah
                                          const AppSvgIcon(
                                            KawaloVectors.check,
                                            size: 28,
                                            color: Colors.white,
                                          ),

                                          // Urutan pilihan di kanan bawah ikon
                                          Positioned(
                                            left: 20,
                                            top: 14,
                                            child: Text(
                                              '${selectionIndex + 1}',
                                              style: theme
                                                  .typography
                                                  .emphasized
                                                  .labelMedium
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey<String>(
                                        'unselected_overlay',
                                      ),
                                    ),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (photo.path != null && photo.path!.isNotEmpty)
                                Image.file(
                                  File(photo.path!),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  excludeFromSemantics: true,
                                  frameBuilder:
                                      (
                                        context,
                                        child,
                                        frame,
                                        wasSynchronouslyLoaded,
                                      ) {
                                        if (wasSynchronouslyLoaded ||
                                            frame != null) {
                                          return child;
                                        }
                                        return const AppImagePlaceholder(
                                          borderRadius: BorderRadius.zero,
                                          width: double.infinity,
                                          height: double.infinity,
                                          iconSize: 24,
                                          iconPath: KawaloVectors.image02Filled,
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const AppImagePlaceholder(
                                        borderRadius: BorderRadius.zero,
                                        width: double.infinity,
                                        height: double.infinity,
                                        iconSize: 24,
                                        iconPath: KawaloVectors.imageNotFound01,
                                      ),
                                )
                              else
                                const AppImagePlaceholder(
                                  borderRadius: BorderRadius.zero,
                                  width: double.infinity,
                                  height: double.infinity,
                                  iconSize: 24,
                                  iconPath: KawaloVectors.image02Filled,
                                ),
                              // Scrim halus pada foto yang terpilih dengan
                              // transisi animasi fade.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedContainer(
                                    duration: isReducedMotion
                                        ? Duration.zero
                                        : AppDuration.short4,
                                    curve: AppMotion.standard,
                                    color: isSelected
                                        ? colorScheme.scrim.withValues(
                                            alpha: 0.24,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Tombol Hapus Mengambang di Pojok Kanan Atas
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SizedBox(
                          width: _deleteButtonSize,
                          height: _deleteButtonSize,
                          child: AppIconButton(
                            key: ValueKey<String>(
                              'remove_captured_photo_$photoKey',
                            ),
                            onPressed: () => onRemovePhoto(index),
                            semanticLabel: 'Hapus foto ke-${index + 1}',
                            size: AppIconButtonSize.xs,
                            visualSize: const Size(
                              _deleteButtonSize,
                              _deleteButtonSize,
                            ),
                            haptic: M3EHapticFeedback.light,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStatePropertyAll(
                                colorScheme.error,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                colorScheme.onError,
                              ),
                              side: WidgetStatePropertyAll(
                                BorderSide(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            icon: AppSvgIcon(
                              KawaloVectors.cancel01,
                              size: 12,
                              color: colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // Animasi pengempisan keluar (exit collapse) saat foto dihapus.
            // Tanpa ClipRect agar thumbnail tidak terpotong (terselip/terswipe).
            final isRemoving =
                photo.path != null && photo.path == removingPhotoPath;
            if (isRemoving && !isReducedMotion) {
              return SizedBox(
                key: ValueKey<String>('tray_item_removing_$photoKey'),
                height: _itemSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1, end: 0),
                  duration: AppDuration.short4,
                  curve: Curves.easeInCubic,
                  builder: (context, val, child) {
                    return SizedBox(
                      width: _itemSize * val,
                      height: _itemSize,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: _itemSize,
                        maxWidth: _itemSize,
                        minHeight: _itemSize,
                        maxHeight: _itemSize,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.80 + (0.20 * val),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: cardWidget,
                ),
              );
            }

            // Animasi pemekaran masuk (enter expand) saat foto baru ditangkap.
            // Tanpa ClipRect agar thumbnail tampil utuh dan mulus tanpa
            // efek terpotong (swipe-cut).
            if (isNewest && !isReducedMotion) {
              return SizedBox(
                key: ValueKey<String>('tray_item_animated_$photoKey'),
                height: _itemSize,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey<String>('tray_newest_$photoKey'),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppDuration.medium2,
                  curve: AppMotion.emphasized,
                  builder: (context, val, child) {
                    return SizedBox(
                      width: _itemSize * val,
                      height: _itemSize,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: _itemSize,
                        maxWidth: _itemSize,
                        minHeight: _itemSize,
                        maxHeight: _itemSize,
                        child: Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.85 + (0.15 * val),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: cardWidget,
                ),
              );
            }

            return cardWidget;
          },
        ),
      ),
    );
  }
}
