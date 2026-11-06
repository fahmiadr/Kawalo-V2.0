import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';

/// Sumber pengambilan foto pada formulir informasi.
enum InformationPhotoSource {
  /// Mengambil foto langsung dengan kamera ponsel.
  camera,

  /// Memilih foto dari galeri perangkat.
  gallery,
}

/// Modal bottom sheet resmi untuk memilih sumber foto lampiran
/// (Kamera vs Galeri) berstandar Material 3 Expressive.
class InformationPhotoSourceBottomSheet extends StatelessWidget {
  /// Membuat instance [InformationPhotoSourceBottomSheet].
  const InformationPhotoSourceBottomSheet({super.key});

  /// Menampilkan bottom sheet pemilihan sumber foto.
  static Future<InformationPhotoSource?> show(BuildContext context) {
    return showAppBottomSheet<InformationPhotoSource>(
      context: context,
      child: const InformationPhotoSourceBottomSheet(),
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
                ),
              ),
              AppSpacing.vGap50,
              Text(
                'Lampirkan foto kegiatan atau dokumentasi penting.',
                style: theme.typeScale.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGap300,
              AppOptionTile(
                vectorIcon: KawaloVectors.camera01,
                title: 'Kamera',
                subtitle: 'Ambil foto langsung',
                onTap: () =>
                    Navigator.of(context).pop(InformationPhotoSource.camera),
              ),
              AppSpacing.vGap150,
              AppOptionTile(
                vectorIcon: KawaloVectors.images,
                title: 'Galeri',
                subtitle: 'Pilih foto dari galeri',
                onTap: () =>
                    Navigator.of(context).pop(InformationPhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
