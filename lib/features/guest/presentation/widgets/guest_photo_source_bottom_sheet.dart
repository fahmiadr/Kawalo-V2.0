import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';

/// Sumber pengambilan foto pada formulir data tamu.
enum GuestPhotoSource {
  /// Mengambil foto langsung dengan kamera ponsel.
  camera,

  /// Memilih foto dari galeri perangkat.
  gallery,
}

/// Modal bottom sheet resmi untuk memilih sumber foto lampiran
/// (Kamera vs Galeri) berstandar Material 3 Expressive.
class GuestPhotoSourceBottomSheet extends StatelessWidget {
  /// Membuat instance [GuestPhotoSourceBottomSheet].
  const GuestPhotoSourceBottomSheet({super.key});

  /// Menampilkan bottom sheet pemilihan sumber foto tamu.
  static Future<GuestPhotoSource?> show(BuildContext context) {
    return showAppBottomSheet<GuestPhotoSource>(
      context: context,
      child: const GuestPhotoSourceBottomSheet(),
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
                'Pilih Sumber Foto',
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vGap50,
              Text(
                'Lampirkan foto identitas atau wajah tamu.',
                style: theme.typeScale.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGap300,
              AppOptionTile(
                title: 'Kamera',
                subtitle: 'Ambil foto tamu langsung menggunakan kamera ponsel',
                vectorIcon: KawaloVectors.camera01,
                onTap: () => Navigator.of(context).pop(GuestPhotoSource.camera),
              ),
              AppSpacing.vGap150,
              AppOptionTile(
                title: 'Galeri',
                subtitle: 'Pilih foto yang tersimpan di galeri perangkat',
                vectorIcon: KawaloVectors.images,
                onTap: () =>
                    Navigator.of(context).pop(GuestPhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
