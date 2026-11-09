import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/presentation/extensions/incident_ui_extension.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_photos_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_detail/incident_detail_summary_card.dart';

/// Bagian atas thread detail: tag kategori/status, kartu ringkasan, kartu
/// foto bukti, dan judul seksi diskusi.
class IncidentDetailHeaderCard extends StatelessWidget {
  /// Membuat instance [IncidentDetailHeaderCard].
  const IncidentDetailHeaderCard({
    required this.incident,
    required this.repliesCount,
    super.key,
  });

  /// Insiden yang ditampilkan.
  final IncidentEntity incident;

  /// Jumlah balasan pada thread diskusi.
  final int repliesCount;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedScale = theme.typography.emphasized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Meta Atas (Kategori & Status) ─────────────────────────────
        Wrap(
          spacing: AppSpacing.space100,
          runSpacing: AppSpacing.space100,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTag(
              label: incident.displayCategory,
              variant: AppTagVariant.secondary,
            ),
            AppTag(
              label: incident.displayStatusLabel,
              variant: incident.statusVariant,
              size: AppTagSize.small,
            ),
          ],
        ),

        AppSpacing.vGap200,

        IncidentDetailSummaryCard(incident: incident),

        // ── Kartu Bukti Foto Laporan Awal (jika ada) ────────────────────
        if (incident.photos.isNotEmpty) ...[
          AppSpacing.vGap200,
          IncidentDetailPhotosCard(incident: incident),
        ],

        AppSpacing.vGap200,

        // ── Header Seksi Diskusi & Koordinasi ─────────────────────────
        Row(
          children: [
            const AppSvgIcon.color(KawaloColorVectors.log1, size: 24),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                'Diskusi & Koordinasi ($repliesCount)',
                style: emphasizedScale.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
