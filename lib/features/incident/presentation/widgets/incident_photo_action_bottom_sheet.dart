import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_action_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';

/// Organism modal bottom sheet untuk menu opsi aksi pada foto tertentu
/// (Buka foto, Jadikan foto utama, Geser kiri/kanan, Hapus)
/// berbasis Material 3 Expressive.
class IncidentPhotoActionBottomSheet extends StatelessWidget {
  /// Membuat instance [IncidentPhotoActionBottomSheet].
  const IncidentPhotoActionBottomSheet({
    required this.item,
    required this.index,
    required this.totalPhotos,
    required this.onViewPhoto,
    required this.onMakePrimary,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDelete,
    super.key,
  });

  /// Media foto yang sedang dipilih.
  final IncidentMediaItem item;

  /// Indeks posisi foto (0-indexed).
  final int index;

  /// Total jumlah foto yang terlampir.
  final int totalPhotos;

  /// Callback saat memilih "Buka foto".
  final VoidCallback onViewPhoto;

  /// Callback saat memilih "Jadikan foto utama".
  final VoidCallback onMakePrimary;

  /// Callback saat memilih "Geser ke kiri".
  final VoidCallback onMoveLeft;

  /// Callback saat memilih "Geser ke kanan".
  final VoidCallback onMoveRight;

  /// Callback saat memilih "Hapus foto ini".
  final VoidCallback onDelete;

  /// Menampilkan [IncidentPhotoActionBottomSheet] via [showAppBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required IncidentMediaItem item,
    required int index,
    required int totalPhotos,
    required VoidCallback onViewPhoto,
    required VoidCallback onMakePrimary,
    required VoidCallback onMoveLeft,
    required VoidCallback onMoveRight,
    required VoidCallback onDelete,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      child: IncidentPhotoActionBottomSheet(
        item: item,
        index: index,
        totalPhotos: totalPhotos,
        onViewPhoto: onViewPhoto,
        onMakePrimary: onMakePrimary,
        onMoveLeft: onMoveLeft,
        onMoveRight: onMoveRight,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space200,
            right: AppSpacing.space200,
            top: AppSpacing.space150,
            bottom: AppSpacing.space300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space150,
                  vertical: AppSpacing.space50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.typography.emphasized.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGap25,
                    Text(
                      'Foto ${index + 1} dari $totalPhotos',
                      style: theme.typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGap100,
              AppActionTile(
                vectorIcon: KawaloVectors.view,
                title: 'Buka foto',
                onTap: onViewPhoto,
              ),
              if (index > 0)
                AppActionTile(
                  vectorIcon: KawaloVectors.arrowUp03,
                  title: 'Jadikan foto utama',
                  onTap: onMakePrimary,
                ),
              if (index > 0)
                AppActionTile(
                  vectorIcon: KawaloVectors.arrowLeft02,
                  title: 'Geser ke kiri',
                  onTap: onMoveLeft,
                ),
              if (index < totalPhotos - 1)
                AppActionTile(
                  vectorIcon: KawaloVectors.arrowRight02,
                  title: 'Geser ke kanan',
                  onTap: onMoveRight,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.space50),
                child: AppDivider(),
              ),
              AppActionTile(
                vectorIcon: KawaloVectors.delete01,
                title: 'Hapus foto ini',
                isDestructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
