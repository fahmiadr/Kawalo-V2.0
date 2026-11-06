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
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

/// Molecule widget untuk thumbnail foto individual dalam Grid 2-kolom
/// lengkap dengan badge urutan, tombol hapus cepat, menu opsi,
/// animasi terbang [Hero], serta respon penekanan Material 3 Expressive
/// (*Corner Radius Compression* & *State Layer* dengan skala netral 1.0)
/// menggunakan komponen fondasi [AppMorphingSurface] demi menjaga kestabilan
/// posisi kontrol overlay bersarang (*nested actions*).
class InformationPhotoThumbnail extends StatelessWidget {
  /// Membuat instance [InformationPhotoThumbnail].
  const InformationPhotoThumbnail({
    required this.item,
    required this.index,
    required this.isSubmitting,
    required this.onTap,
    required this.onRemove,
    required this.onMoreOptions,
    this.isLoading,
    this.borderRadius,
    this.heroTag,
    this.heroTagPrefix,
    super.key,
  });

  /// Item media foto yang dirender.
  final InformationFormMediaItem item;

  /// Indeks urutan foto (0-indexed).
  final int index;

  /// Menandakan apakah formulir sedang dalam status submit.
  final bool isSubmitting;

  /// Callback saat gambar utama diketuk (membuka AppImageViewer).
  final VoidCallback onTap;

  /// Callback saat tombol silang cepat diketuk.
  final VoidCallback onRemove;

  /// Callback saat tombol menu titik tiga diketuk.
  final VoidCallback onMoreOptions;

  /// Menandakan secara eksplisit apakah foto sedang dalam proses
  /// pemuatan/kompresi. Jika bernilai null, akan menggunakan nilai dari
  /// [InformationFormMediaItem.isLoading].
  final bool? isLoading;

  /// Border radius kustom opsional. Default menggunakan
  /// [AppRadius.borderMedium] (12dp).
  final BorderRadius? borderRadius;

  /// Tag kustom eksplisit untuk animasi Hero ke `AppImageViewer`.
  final String? heroTag;

  /// Prefiks opsional untuk kalkulasi Hero tag otomatis
  /// (`${heroTagPrefix}_$index`).
  final String? heroTagPrefix;

  /// Tag Hero efektif yang digunakan untuk transisi spasial ke
  /// `AppImageViewer`.
  String get effectiveHeroTag =>
      heroTag ??
      (heroTagPrefix != null
          ? '${heroTagPrefix}_$index'
          : 'app_image_viewer_${item.displaySource}_$index');

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveLoading = isLoading ?? item.isLoading;
    final isInteractive = !isSubmitting && !effectiveLoading;
    final restingBorderRadius = borderRadius ?? AppRadius.borderMedium;

    final semanticLabel = effectiveLoading
        ? 'Foto ke-${index + 1} sedang dimuat'
        : 'Lihat foto ke-${index + 1}: ${item.name}';

    Widget imageContent;
    if (item.bytes != null) {
      imageContent = Image.memory(
        item.bytes!,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const AppImagePlaceholder(
            borderRadius: BorderRadius.zero,
            width: double.infinity,
            height: double.infinity,
            icon: AppLoadingIndicator(
              size: AppLoadingIndicatorSize.small,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          iconPath: KawaloVectors.images,
          iconSize: 24,
        ),
      );
    } else if (!kIsWeb &&
        item.path != null &&
        File(item.path!).existsSync()) {
      imageContent = Image.file(
        File(item.path!),
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const AppImagePlaceholder(
            borderRadius: BorderRadius.zero,
            width: double.infinity,
            height: double.infinity,
            icon: AppLoadingIndicator(
              size: AppLoadingIndicatorSize.small,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const AppImagePlaceholder(
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
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => const AppImagePlaceholder(
          borderRadius: BorderRadius.zero,
          width: double.infinity,
          height: double.infinity,
          icon: AppLoadingIndicator(
            size: AppLoadingIndicatorSize.small,
          ),
        ),
        errorWidget: (_, __, ___) => const AppImagePlaceholder(
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
        key: ValueKey<String>('photo_thumbnail_$index'),
        onTap: isInteractive ? onTap : null,
        enabled: isInteractive,
        restingBorderRadius: restingBorderRadius,
        semanticLabel: semanticLabel,
        semanticButton: isInteractive,
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            // Indikator Pemuatan / Kompresi Foto (Overlay Scrim)
            if (effectiveLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: colorScheme.scrim.withValues(alpha: 0.54),
                  child: const Center(
                    child: AppLoadingIndicator(
                      size: AppLoadingIndicatorSize.small,
                    ),
                  ),
                ),
              ),

            // ── Bar Kontrol Atas (Badge Urutan & Tombol Hapus Sejajar) ──
            Positioned(
              top: AppSpacing.space50,
              left: AppSpacing.space50,
              right: AppSpacing.space50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Urutan Foto High Emphasis M3 Expressive
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

                  // Tombol Hapus Silang Cepat M3 Expressive
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: AppIconButton(
                      onPressed: isSubmitting ? null : onRemove,
                      semanticLabel: 'Hapus foto ${index + 1}',
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

            // Tombol Menu Aksi Foto di pojok kanan bawah
            if (!effectiveLoading)
              Positioned(
                bottom: AppSpacing.space50,
                right: AppSpacing.space50,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: AppIconButton(
                    onPressed: isSubmitting ? null : onMoreOptions,
                    semanticLabel: 'Opsi foto ${index + 1}',
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
                      KawaloVectors.moreVerticalCircle01,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        child: Hero(
          tag: effectiveHeroTag,
          child: imageContent,
        ),
      ),
    );
  }
}
