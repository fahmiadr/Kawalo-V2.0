/// @docImport 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
library;

import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_upload_overlay.dart';

/// Thumbnail foto individual laporan insiden dalam Grid 2-kolom
/// lengkap dengan badge urutan, tombol hapus cepat, tombol opsi,
/// animasi Hero, serta respon penekanan Material 3 Expressive
/// menggunakan [AppMorphingSurface].
class IncidentPhotoThumbnail extends StatelessWidget {
  /// Membuat instance [IncidentPhotoThumbnail].
  const IncidentPhotoThumbnail({
    required this.item,
    required this.index,
    required this.isSubmitting,
    required this.onTap,
    required this.onRemove,
    required this.onMoreOptions,
    this.onRetry,
    this.borderRadius,
    this.heroTag,
    this.heroTagPrefix,
    super.key,
  });

  /// Item media foto insiden.
  final IncidentMediaItem item;

  /// Indeks urutan foto (0-indexed).
  final int index;

  /// Status apakah formulir sedang dikirimkan.
  final bool isSubmitting;

  /// Callback saat gambar utama diketuk untuk membuka layar penuh.
  final VoidCallback onTap;

  /// Callback saat tombol silang cepat diketuk.
  final VoidCallback onRemove;

  /// Callback saat tombol menu titik tiga diketuk.
  final VoidCallback onMoreOptions;

  /// Callback untuk mengunggah ulang foto yang gagal diunggah.
  final VoidCallback? onRetry;

  /// Radius sudut kustom opsional.
  final BorderRadius? borderRadius;

  /// Tag kustom eksplisit untuk animasi Hero ke [AppImageViewer].
  final String? heroTag;

  /// Prefiks opsional untuk kalkulasi tag Hero otomatis.
  final String? heroTagPrefix;

  /// Tag Hero efektif yang digunakan untuk transisi spasial.
  String get effectiveHeroTag =>
      heroTag ??
      (heroTagPrefix != null
          ? '${heroTagPrefix}_$index'
          : 'incident_form_photo_$index');

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final isInteractive = !isSubmitting;
    final restingBorderRadius = borderRadius ?? AppRadius.borderMedium;

    final semanticLabel = 'Lihat foto insiden ke-${index + 1}: ${item.name}';

    Widget imageContent;
    if (item.bytes != null) {
      imageContent = Image.memory(
        item.bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const AppImagePlaceholder(
            borderRadius: BorderRadius.zero,
            width: double.infinity,
            height: double.infinity,
            icon: AppLoadingIndicator(size: AppLoadingIndicatorSize.small),
          );
        },
        errorBuilder: (_, _, _) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          iconPath: KawaloVectors.images,
          iconSize: 24,
        ),
      );
    } else if (!kIsWeb && item.path != null && File(item.path!).existsSync()) {
      imageContent = Image.file(
        File(item.path!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const AppImagePlaceholder(
            borderRadius: BorderRadius.zero,
            width: double.infinity,
            height: double.infinity,
            icon: AppLoadingIndicator(size: AppLoadingIndicatorSize.small),
          );
        },
        errorBuilder: (_, _, _) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          iconPath: KawaloVectors.images,
          iconSize: 24,
        ),
      );
    } else if (item.remoteUrl != null && item.remoteUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: item.remoteUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          icon: AppLoadingIndicator(size: AppLoadingIndicatorSize.small),
        ),
        errorWidget: (_, _, _) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          iconSize: 24,
        ),
      );
    } else {
      imageContent = const AppImagePlaceholder(
        borderRadius: BorderRadius.zero,
        width: double.infinity,
        height: double.infinity,
        iconPath: KawaloVectors.images,
        iconSize: 24,
      );
    }

    return Material(
      color: Colors.transparent,
      child: AppMorphingSurface(
        key: ValueKey<String>('incident_photo_thumbnail_$index'),
        onTap: isInteractive ? onTap : null,
        enabled: isInteractive,
        restingBorderRadius: restingBorderRadius,
        semanticLabel: semanticLabel,
        semanticButton: isInteractive,
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            // Lives in the overlay (not the child) so the retry button can
            // receive taps; the control buttons below stay on top of it.
            Positioned.fill(
              child: IncidentPhotoUploadOverlay(
                item: item,
                onRetry: onRetry,
                showWaiting: isSubmitting,
              ),
            ),
            // Bar Kontrol Atas (Badge Urutan & Tombol Hapus Cepat)
            Positioned(
              top: AppSpacing.space50,
              left: AppSpacing.space50,
              right: AppSpacing.space50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Urutan Foto M3 Expressive
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space100,
                        vertical: AppSpacing.space25,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadius.borderFull,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.typography.emphasized.labelSmall.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Hapus Silang Cepat
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: AppIconButton(
                      onPressed: isSubmitting ? null : onRemove,
                      semanticLabel: 'Hapus foto insiden ke-${index + 1}',
                      size: AppIconButtonSize.xs,
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
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Menu Aksi Foto di sudut kanan bawah
            Positioned(
              bottom: AppSpacing.space50,
              right: AppSpacing.space50,
              child: SizedBox(
                width: 28,
                height: 28,
                child: AppIconButton(
                  onPressed: isSubmitting ? null : onMoreOptions,
                  semanticLabel: 'Opsi foto insiden ke-${index + 1}',
                  size: AppIconButtonSize.xs,
                  decoration: M3EIconButtonDecoration(
                    backgroundColor: WidgetStatePropertyAll(
                      colorScheme.scrim.withValues(alpha: 0.60),
                    ),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                  ),
                  icon: const AppSvgIcon(
                    KawaloVectors.moreVerticalCircle01,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Hero(tag: effectiveHeroTag, child: imageContent),
      ),
    );
  }
}
