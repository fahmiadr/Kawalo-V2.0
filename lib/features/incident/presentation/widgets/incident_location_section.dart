import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_form_section.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

/// Form section showing the incident GPS point: searching, resolved (static
/// map) or unavailable. The report can always be sent without a location.
class IncidentLocationSection extends StatelessWidget {
  const IncidentLocationSection({
    required this.latitude,
    required this.longitude,
    required this.isResolving,
    required this.isBusy,
    required this.onRefresh,
    required this.onClear,
    this.error,
    this.reverseGeocodeService,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final bool isResolving;

  /// Whether the form is uploading or sending; locks the actions.
  final bool isBusy;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onClear;
  final ReverseGeocodeService? reverseGeocodeService;

  bool get _hasLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;

    return AppFormSection.uncontained(
      title: 'Lokasi kejadian',
      subtitle:
          'Titik GPS perangkat dilampirkan otomatis. Laporan tetap dapat '
          'dikirim tanpa lokasi.',
      child: _hasLocation
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.borderMedium,
                  child: AppStaticMap(
                    latitude: latitude,
                    longitude: longitude,
                    markerStyle: AppStaticMapMarkerStyle.dot,
                    reverseGeocodeService: reverseGeocodeService,
                  ),
                ),
                AppSpacing.vGap150,
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.space150,
                  runSpacing: AppSpacing.space100,
                  children: [
                    AppButton(
                      style: AppButtonColor.outlined,
                      onPressed: (isBusy || isResolving) ? null : onRefresh,
                      child: Text(
                        isResolving ? 'Mencari lokasi...' : 'Perbarui lokasi',
                      ),
                    ),
                    AppButton(
                      style: AppButtonColor.text,
                      onPressed: isBusy ? null : onClear,
                      semanticLabel: 'Hapus lokasi laporan',
                      decoration: AppButtonDecoration(
                        foregroundColor: WidgetStatePropertyAll<Color?>(
                          colorScheme.error,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(KawaloVectors.delete01, size: 16),
                          AppSpacing.hGapXs,
                          Text('Hapus lokasi'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : AppFormEmptyPlaceholder(
              title: isResolving
                  ? 'Mencari lokasi...'
                  : error != null
                  ? 'Lokasi tidak tersedia'
                  : 'Tanpa lokasi',
              subtitle: isResolving
                  ? 'Menunggu sinyal GPS perangkat'
                  : error != null
                  ? '$error Ketuk untuk mencoba lagi.'
                  : 'Ketuk untuk melampirkan lokasi saat ini',
              vectorIcon: KawaloVectors.mapPin,
              isLoading: isResolving,
              onTap: (isBusy || isResolving) ? null : onRefresh,
            ),
    );
  }
}
