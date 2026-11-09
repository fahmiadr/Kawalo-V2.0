import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Kartu ringkasan metrik kedinasan personil operasional pada layar detail.
///
/// Menampilkan perbandingan waktu dan status awal dinas (laporan pertama)
/// dengan waktu dan status pembaruan dinas terakhir.
class OperationalDetailSummaryCard extends StatelessWidget {
  /// Membuat instance [OperationalDetailSummaryCard].
  const OperationalDetailSummaryCard({required this.item, super.key});

  /// Data personil operasional yang ditampilkan.
  final OperationalItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final initialStatus = item.timeline.isNotEmpty
        ? item.timeline.last.displayState
        : item.displayLatestState;

    final latestStatus = item.displayLatestState;

    final semanticLabel =
        'Ringkasan dinas harian, mulai dinas '
        '${item.displayFirstActivityTime} status $initialStatus, '
        'status terkini ${item.displayLatestStateTime} '
        'status $latestStatus';

    return AppCard(
      semanticLabel: semanticLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Kartu Ringkasan ──────────────────────────────────────
          Row(
            children: [
              const AppSvgIcon.color(KawaloColorVectors.calendarStar, size: 32),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Ringkasan dinas harian',
                  style: emphasizedTypeScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          // ── Pemisah ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // ── Baris Metrik (Mulai Dinas vs Status Terkini) ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Mulai Dinas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai dinas',
                      style: typeScale.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      item.displayFirstActivityTime,
                      style: emphasizedTypeScale.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      initialStatus,
                      style: typeScale.labelMedium.copyWith(
                        color: colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              AppSpacing.hGap200,

              // Kolom Status Terkini
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status terkini',
                      style: typeScale.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      item.displayLatestStateTime,
                      style: emphasizedTypeScale.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.vGap25,
                    Text(
                      latestStatus,
                      style: typeScale.labelMedium.copyWith(
                        color: colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
