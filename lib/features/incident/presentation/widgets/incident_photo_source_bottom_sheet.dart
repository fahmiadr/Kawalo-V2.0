import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';

/// Sumber pengambilan foto pada formulir laporan insiden.
enum IncidentPhotoSource {
  /// Mengambil foto langsung dengan kamera ponsel.
  camera,

  /// Memilih foto dari galeri perangkat.
  gallery,
}

/// Modal bottom sheet untuk memilih sumber foto lampiran insiden
/// (Kamera vs Galeri) berstandar Material 3 Expressive.
class IncidentPhotoSourceBottomSheet extends StatelessWidget {
  /// Membuat instance [IncidentPhotoSourceBottomSheet].
  const IncidentPhotoSourceBottomSheet({super.key});

  /// Menampilkan bottom sheet pemilihan sumber foto insiden.
  static Future<IncidentPhotoSource?> show(BuildContext context) {
    return showAppBottomSheet<IncidentPhotoSource>(
      context: context,
      child: const IncidentPhotoSourceBottomSheet(),
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
            left: AppSpacing.space300,
            right: AppSpacing.space300,
            top: AppSpacing.space100,
            bottom: AppSpacing.space300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih sumber foto',
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vGap50,
              Text(
                'Lampirkan foto bukti kondisi atau kejadian di lapangan.',
                style: theme.typeScale.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGap300,
              AppOptionTile(
                title: 'Kamera',
                subtitle: 'Ambil foto insiden langsung menggunakan kamera',
                vectorIcon: KawaloVectors.camera01,
                onTap: () =>
                    Navigator.of(context).pop(IncidentPhotoSource.camera),
              ),
              AppSpacing.vGap150,
              AppOptionTile(
                title: 'Galeri',
                subtitle: 'Pilih foto insiden dari galeri penyimpanan',
                vectorIcon: KawaloVectors.images,
                onTap: () =>
                    Navigator.of(context).pop(IncidentPhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
