import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';

/// Kartu bukti foto laporan awal dengan thumbnail yang membuka image viewer.
class IncidentDetailPhotosCard extends StatelessWidget {
  /// Membuat instance [IncidentDetailPhotosCard].
  const IncidentDetailPhotosCard({required this.incident, super.key});

  /// Insiden yang fotonya ditampilkan.
  final IncidentEntity incident;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedScale = theme.typography.emphasized;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AppSvgIcon(KawaloVectors.camera01, size: 24),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Foto Bukti Laporan (${incident.photos.length})',
                  style: emphasizedScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap150,
          Wrap(
            spacing: AppSpacing.space100,
            runSpacing: AppSpacing.space100,
            children: List.generate(incident.photos.length, (photoIndex) {
              final photoUrl = incident.photos[photoIndex];
              return GestureDetector(
                onTap: () {
                  AppImageViewer.show(
                    context,
                    imageUrls: incident.photos,
                    initialIndex: photoIndex,
                  );
                },
                child: ClipRRect(
                  borderRadius: AppRadius.borderMedium,
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox(
                      width: 88,
                      height: 88,
                      child: AppImagePlaceholder(),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
