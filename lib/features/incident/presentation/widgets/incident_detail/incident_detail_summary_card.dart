import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';

/// Kartu ringkasan insiden: judul, pelapor, deskripsi, dan koordinat GPS.
class IncidentDetailSummaryCard extends StatelessWidget {
  /// Membuat instance [IncidentDetailSummaryCard].
  const IncidentDetailSummaryCard({required this.incident, super.key});

  /// Insiden yang diringkas.
  final IncidentEntity incident;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
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
          // Header: Avatar 40x40, Judul & Pelapor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClipRRect(
                borderRadius: AppRadius.borderMedium,
                child: AppSvgIcon.color(KawaloColorVectors.incident1, size: 40),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      incident.displayTitle,
                      style: emphasizedScale.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      'Dilaporkan oleh ${incident.displayReporter} • '
                      '${incident.displayCreatedAt}',
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // Deskripsi Kejadian
          if (incident.description != null &&
              incident.description!.trim().isNotEmpty) ...[
            Text(
              'Deskripsi kejadian',
              style: emphasizedScale.titleSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.vGap50,
            SelectableText(
              incident.displayDescription,
              style: typeScale.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGap150,
          ],

          // Titik Lokasi GPS jika ada
          if (incident.glat != null && incident.glong != null) ...[
            Row(
              children: [
                const AppSvgIcon.color(KawaloColorVectors.location1, size: 20),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Koordinat GPS: ${incident.glat}, ${incident.glong}',
                    style: typeScale.labelMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
