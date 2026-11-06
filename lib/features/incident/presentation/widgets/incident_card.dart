import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_screen.dart'
    show IncidentScreen;

/// Komponen kartu ringkasan insiden untuk item daftar pada [IncidentScreen].
///
/// Mematuhi spesifikasi Material 3 Expressive, token tema sistem Kawalo,
/// serta konsisten dan serasi dengan tampilan kartu fitur Guest.
class IncidentCard extends StatelessWidget {
  /// Membuat instance [IncidentCard].
  const IncidentCard({
    required this.incident,
    required this.onTap,
    super.key,
  });

  /// Entitas insiden yang ditampilkan pada kartu.
  final IncidentEntity incident;

  /// Callback navigasi saat kartu ditekan.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel =
        'Laporan insiden ${incident.displayTitle}, '
        'kategori ${incident.displayCategory}, '
        'status ${incident.displayStatusLabel}, '
        'dilaporkan oleh ${incident.displayReporter}, '
        'waktu ${incident.displayRelativeTime}';

    return AppCard(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar Insiden, Judul, Pelapor & Chevron ───────────
          Row(
            children: [
              _buildAvatar(context),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incident.displayTitle,
                            style: emphasizedTypeScale.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.hGapXs,
                        const AppSvgIcon(
                          KawaloVectors.arrowRight01,
                          size: 24,
                        ),
                      ],
                    ),
                    Text(
                      '${incident.displayReporter} • '
                      '${incident.displayRelativeTime}',
                      style: typeScale.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.vGapSm,

          // ── Tag Kategori Insiden ─────────────────────────────────────────
          AppTag(
            label: incident.displayCategory,
            variant: AppTagVariant.secondary,
          ),

          // ── Garis Pemisah (AppDivider) ───────────────────────────────────
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // ── Detail Informasi Insiden ─────────────────────────────────────
          if (incident.description != null &&
              incident.description!.trim().isNotEmpty) ...[
            _buildDetailRow(
              context: context,
              iconPath: KawaloColorVectors.fileEdit,
              text: incident.displayDescription,
            ),
            AppSpacing.vGap50,
          ],

          _buildTimestampAndStatusRow(context: context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(
        KawaloColorVectors.incident1,
        size: 40,
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String iconPath,
    required String text,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Row(
      children: [
        AppSvgIcon.color(
          iconPath,
          size: 20,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            text,
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampAndStatusRow({
    required BuildContext context,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final dateText = incident.isOpen
        ? 'Dilaporkan: ${incident.displayCreatedAt}'
        : 'Diselesaikan: ${incident.displayResolvedAt}';

    return Row(
      children: [
        const AppSvgIcon.color(
          KawaloColorVectors.timeRotation,
          size: 20,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            dateText,
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (incident.photos.isNotEmpty) ...[
          AppSpacing.hGapSm,
          AppTag(
            label: '${incident.photos.length} foto',
            variant: AppTagVariant.neutral,
            size: AppTagSize.small,
          ),
        ],
        AppSpacing.hGapSm,
        AppTag(
          label: incident.displayStatusLabel,
          variant: incident.statusVariant,
          size: AppTagSize.small,
        ),
      ],
    );
  }
}
