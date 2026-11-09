import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';

/// Sumber penentuan titik lokasi pada formulir informasi.
enum InformationLocationSource {
  /// Mendeteksi lokasi saat ini menggunakan GPS perangkat.
  currentLocation,

  /// Memilih titik lokasi secara interaktif di peta.
  pickOnMap,
}

/// Modal bottom sheet resmi untuk memilih sumber penentuan titik lokasi
/// (Lokasi saat ini vs Pilih di peta) berstandar Material 3 Expressive.
class InformationLocationSourceBottomSheet extends StatelessWidget {
  /// Membuat instance [InformationLocationSourceBottomSheet].
  const InformationLocationSourceBottomSheet({super.key});

  /// Menampilkan bottom sheet pemilihan sumber lokasi.
  static Future<InformationLocationSource?> show(BuildContext context) {
    return showAppBottomSheet<InformationLocationSource>(
      context: context,
      child: const InformationLocationSourceBottomSheet(),
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
                'Tentukan titik lokasi',
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.vGap50,
              Text(
                'Pilih metode untuk menandai posisi lokasi kejadian '
                'atau acara.',
                style: theme.typeScale.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGap300,
              AppOptionTile(
                vectorIcon: KawaloVectors.gps01,
                title: 'Lokasi saat ini',
                subtitle:
                    'Deteksi posisi sekarang secara otomatis menggunakan GPS',
                onTap: () => Navigator.of(
                  context,
                ).pop(InformationLocationSource.currentLocation),
              ),
              AppSpacing.vGap150,
              AppOptionTile(
                vectorIcon: KawaloVectors.mapPin,
                title: 'Pilih di peta',
                subtitle: 'Geser dan perbesar peta untuk menandai titik lokasi',
                onTap: () => Navigator.of(
                  context,
                ).pop(InformationLocationSource.pickOnMap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
