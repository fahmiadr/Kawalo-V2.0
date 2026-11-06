import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Bilah pratinjau thumbnail foto yang dilampirkan sebelum dikirimkan.
///
/// Menyediakan tombol hapus individual dengan target sentuh minimal 48x48dp.
class IncidentAttachmentPreview extends StatelessWidget {
  /// Membuat instance [IncidentAttachmentPreview].
  const IncidentAttachmentPreview({
    required this.photos,
    required this.onRemove,
    super.key,
  });

  /// Daftar media item yang dilampirkan.
  final List<IncidentMediaItem> photos;

  /// Callback saat foto dihapus berdasarkan ID.
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space50,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final photo = photos[index];

          Widget imageWidget;
          if (photo.bytes != null) {
            imageWidget = Image.memory(
              photo.bytes!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            );
          } else if (photo.path != null && File(photo.path!).existsSync()) {
            imageWidget = Image.file(
              File(photo.path!),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            );
          } else if (photo.remoteUrl != null) {
            imageWidget = CachedNetworkImage(
              imageUrl: photo.remoteUrl!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => const AppImagePlaceholder(),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            );
          } else {
            imageWidget = Container(
              width: 72,
              height: 72,
              color: colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.photo_outlined),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: AppRadius.borderMedium,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageWidget,
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Semantics(
                  button: true,
                  label: 'Hapus foto lampiran ${index + 1}',
                  child: SizedBox(
                    width: AppStateLayer.minTouchTarget,
                    height: AppStateLayer.minTouchTarget,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: AppSvgIcon(
                            KawaloVectors.cancel01,
                            size: 16,
                            color: colorScheme.error,
                          ),
                          tooltip: 'Hapus foto',
                          onPressed: () => onRemove(photo.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
