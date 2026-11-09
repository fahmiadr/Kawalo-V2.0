import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_address_section.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/map_picker/map_picker_overlay_state.dart';
import 'package:latlong2/latlong.dart' hide Path;

// ============================================================================
// ORGANISM: Map Picker Bottom Overlay
// ============================================================================

/// Organisme kontrol bawah melayang yang menampung FAB GPS, kartu info
/// koordinat, area resolusi alamat, dan tombol konfirmasi titik.
class MapPickerBottomOverlay extends StatelessWidget {
  const MapPickerBottomOverlay({
    required this.state,
    required this.centerListenable,
    required this.onGoToCurrentLocation,
    required this.onConfirm,
    required this.onRetryGeocode,
    super.key,
  });

  /// Status data UI yang mengalir satu arah (UDF).
  final MapPickerOverlayState state;

  /// Posisi koordinat tengah peta real-time.
  final ValueListenable<LatLng> centerListenable;

  /// Pemicu pencarian lokasi saat ini.
  final VoidCallback onGoToCurrentLocation;

  /// Pemicu konfirmasi koordinat terpilih.
  final VoidCallback onConfirm;

  /// Pemicu percobaan ulang resolusi alamat.
  final VoidCallback onRetryGeocode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return Positioned(
      left: AppSpacing.space200,
      right: AppSpacing.space200,
      bottom: AppSpacing.space200,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AppFab(
              onPressed: state.isLocatingUser ? null : onGoToCurrentLocation,
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.primary,
              tooltip: 'Lokasi saat ini',
              icon: state.isLocatingUser
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: AppLoadingIndicator(
                        size: AppLoadingIndicatorSize.small,
                      ),
                    )
                  : const AppSvgIcon(KawaloVectors.gps01, size: 24),
            ),
            AppSpacing.vGap150,
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.space200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CoordinatesDisplay(centerListenable: centerListenable),
                  AppSpacing.vGap100,
                  AddressResolutionSection(
                    state: state,
                    onRetry: onRetryGeocode,
                  ),
                  AppSpacing.vGap200,
                  AppButton(
                    onPressed: state.canConfirm ? onConfirm : null,
                    child: const Text('Pilih titik ini'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
