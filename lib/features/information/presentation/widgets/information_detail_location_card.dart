import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';

/// Kartu visual lokasi GPS dan peta OpenStreetMap (OSM) resmi untuk layar
/// detail informasi.
class InformationDetailLocationCard extends StatelessWidget {
  /// Membuat instance [InformationDetailLocationCard].
  const InformationDetailLocationCard({
    required this.item,
    this.reverseGeocodeService,
    super.key,
  });

  /// Data informasi yang memuat koordinat GPS dan lokasi.
  final InformationItemEntity item;

  /// Layanan opsional untuk reverse geocoding alamat fisik dari koordinat.
  final ReverseGeocodeService? reverseGeocodeService;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final locationTitle =
        item.eventLocation != null && item.eventLocation!.isNotEmpty
        ? item.eventLocation!
        : 'Lokasi kejadian / informasi';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const AppSvgIcon.color(KawaloColorVectors.location1, size: 24),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  locationTitle,
                  style: emphasizedTypeScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.vGap200,
          AppStaticMap(
            latitude: item.glat,
            longitude: item.glong,
            markerStyle: AppStaticMapMarkerStyle.dot,
            locationSemanticLabel:
                'Titik lokasi informasi ${item.displayTitle}',
            reverseGeocodeService: reverseGeocodeService,
            noGpsDescription:
                'Informasi ini dipublikasikan tanpa titik lokasi.',
          ),
        ],
      ),
    );
  }
}
