import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';

/// Komponen kolase gambar dinamis multi-foto (`AppImageCollage`)
/// yang mematuhi standar Material 3 Expressive Design.
///
/// Mendukung layout responsif adaptif berdasarkan jumlah gambar:
/// - 1 Gambar: Layar penuh tunggal.
/// - 2 Gambar: Pembagian 2 kolom vertikal berdampingan (50% / 50%).
/// - 3 Gambar: M3 Expressive Asymmetrical Split
///   (Kiri ~60%, Kanan 2 tumpukan ~40%).
/// - 4 Gambar: Grid 2x2 seimbang.
/// - 5+ Gambar: Grid 2x2 dengan ubin ke-4 menampilkan overlay scrim
///   dan counter `+N`.
class AppImageCollage extends StatelessWidget {
  /// Membuat instance [AppImageCollage].
  const AppImageCollage({
    required this.imageUrls,
    required this.onImageTap,
    super.key,
    this.heroTagPrefix,
    this.height = 240,
  }) : assert(height > 0, 'height harus lebih besar dari 0');

  /// Daftar URL foto yang akan ditampilkan.
  final List<String> imageUrls;

  /// Callback saat foto pada indeks tertentu diketuk.
  final ValueChanged<int> onImageTap;

  /// Prefiks opsional untuk Hero animation matching.
  final String? heroTagPrefix;

  /// Tinggi dari wadah kolase (default 240dp).
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final count = imageUrls.length;

    if (count == 1) {
      return _buildTile(context, 0);
    }

    if (count == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildTile(
              context,
              0,
              borderRadius: const BorderRadius.only(
                topLeft: AppRadius.radiusMedium,
                bottomLeft: AppRadius.radiusMedium,
                topRight: AppRadius.radiusExtraSmall,
                bottomRight: AppRadius.radiusExtraSmall,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space50),
          Expanded(
            child: _buildTile(
              context,
              1,
              borderRadius: const BorderRadius.only(
                topLeft: AppRadius.radiusExtraSmall,
                bottomLeft: AppRadius.radiusExtraSmall,
                topRight: AppRadius.radiusMedium,
                bottomRight: AppRadius.radiusMedium,
              ),
            ),
          ),
        ],
      );
    }

    if (count == 3) {
      // M3 Expressive Asymmetrical Split:
      // Kiri: Hero foto besar (flex 3 ~ 60%)
      // Kanan: Kolom 2 foto tumpuk (flex 2 ~ 40%)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildTile(
              context,
              0,
              borderRadius: const BorderRadius.only(
                topLeft: AppRadius.radiusMedium,
                bottomLeft: AppRadius.radiusMedium,
                topRight: AppRadius.radiusExtraSmall,
                bottomRight: AppRadius.radiusExtraSmall,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space50),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    1,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusExtraSmall,
                      topRight: AppRadius.radiusMedium,
                      bottomLeft: AppRadius.radiusExtraSmall,
                      bottomRight: AppRadius.radiusExtraSmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space50),
                Expanded(
                  child: _buildTile(
                    context,
                    2,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusExtraSmall,
                      bottomLeft: AppRadius.radiusExtraSmall,
                      topRight: AppRadius.radiusExtraSmall,
                      bottomRight: AppRadius.radiusMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    0,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusMedium,
                      topRight: AppRadius.radiusExtraSmall,
                      bottomLeft: AppRadius.radiusExtraSmall,
                      bottomRight: AppRadius.radiusExtraSmall,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space50),
                Expanded(
                  child: _buildTile(
                    context,
                    1,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusExtraSmall,
                      topRight: AppRadius.radiusMedium,
                      bottomLeft: AppRadius.radiusExtraSmall,
                      bottomRight: AppRadius.radiusExtraSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space50),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    2,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusExtraSmall,
                      topRight: AppRadius.radiusExtraSmall,
                      bottomLeft: AppRadius.radiusMedium,
                      bottomRight: AppRadius.radiusExtraSmall,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space50),
                Expanded(
                  child: _buildTile(
                    context,
                    3,
                    borderRadius: const BorderRadius.only(
                      topLeft: AppRadius.radiusExtraSmall,
                      topRight: AppRadius.radiusExtraSmall,
                      bottomLeft: AppRadius.radiusExtraSmall,
                      bottomRight: AppRadius.radiusMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 5+ Foto: Grid 2x2 dengan overlay +N pada tile ke-4 (indeks 3)
    final remainingCount = count - 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildTile(
                  context,
                  0,
                  borderRadius: const BorderRadius.only(
                    topLeft: AppRadius.radiusMedium,
                    topRight: AppRadius.radiusExtraSmall,
                    bottomLeft: AppRadius.radiusExtraSmall,
                    bottomRight: AppRadius.radiusExtraSmall,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space50),
              Expanded(
                child: _buildTile(
                  context,
                  1,
                  borderRadius: const BorderRadius.only(
                    topLeft: AppRadius.radiusExtraSmall,
                    topRight: AppRadius.radiusMedium,
                    bottomLeft: AppRadius.radiusExtraSmall,
                    bottomRight: AppRadius.radiusExtraSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space50),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildTile(
                  context,
                  2,
                  borderRadius: const BorderRadius.only(
                    topLeft: AppRadius.radiusExtraSmall,
                    topRight: AppRadius.radiusExtraSmall,
                    bottomLeft: AppRadius.radiusMedium,
                    bottomRight: AppRadius.radiusExtraSmall,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space50),
              Expanded(
                child: _buildTile(
                  context,
                  3,
                  borderRadius: const BorderRadius.only(
                    topLeft: AppRadius.radiusExtraSmall,
                    topRight: AppRadius.radiusExtraSmall,
                    bottomLeft: AppRadius.radiusExtraSmall,
                    bottomRight: AppRadius.radiusMedium,
                  ),
                  remainingCount: remainingCount,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    int index, {
    BorderRadius borderRadius = AppRadius.borderMedium,
    int? remainingCount,
  }) {
    final imageUrl = imageUrls[index];
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_$index'
        : 'app_image_viewer_${imageUrl}_$index';

    return _AppCollageTile(
      key: ValueKey<String>('collage_tile_$index'),
      imageUrl: imageUrl,
      index: index,
      total: imageUrls.length,
      heroTag: heroTag,
      onTap: () => onImageTap(index),
      borderRadius: borderRadius,
      remainingCount: remainingCount,
    );
  }
}

class _AppCollageTile extends StatelessWidget {
  const _AppCollageTile({
    required this.imageUrl,
    required this.index,
    required this.total,
    required this.heroTag,
    required this.onTap,
    required this.borderRadius,
    this.remainingCount,
    super.key,
  });

  final String imageUrl;
  final int index;
  final int total;
  final String heroTag;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final int? remainingCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);
    final typeScale = AppTheme.typeScaleOf(context);

    final semanticLabel = remainingCount != null && remainingCount! > 0
        ? 'Foto 4 dari $total, dan $remainingCount foto lainnya'
        : 'Foto ${index + 1} dari $total';

    final imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => const AppImagePlaceholder(
        width: double.infinity,
        height: double.infinity,
        iconSize: 32,
      ),
      errorWidget: (_, _, _) => const AppImagePlaceholder(
        width: double.infinity,
        height: double.infinity,
        iconSize: 32,
      ),
    );

    return AppMorphingSurface(
      onTap: onTap,
      restingBorderRadius: borderRadius,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(tag: heroTag, child: imageWidget),
          if (remainingCount != null && remainingCount! > 0)
            ColoredBox(
              color: colorScheme.scrim.withValues(alpha: 0.60),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: typeScale.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
