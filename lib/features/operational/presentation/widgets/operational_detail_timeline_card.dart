import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Kartu jurnal linimasa aktivitas kedinasan personil operasional pada layar
/// detail.
///
/// Menampilkan urutan kronologis pergantian pos jaga dan status aktivitas dinas
/// sepanjang shift harian dengan skema node temporal universal Material 3
/// Expressive.
class OperationalDetailTimelineCard extends StatelessWidget {
  /// Membuat instance [OperationalDetailTimelineCard].
  const OperationalDetailTimelineCard({
    required this.item,
    super.key,
  });

  /// Data personil operasional yang ditampilkan.
  final OperationalItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel = 'Riwayat aktivitas dinas, total '
        '${item.timeline.length} aktivitas';

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
          // ── Header Kartu Linimasa ───────────────────────────────────────
          Row(
            children: [
              const AppSvgIcon.color(
                KawaloColorVectors.filePointToPoint,
                size: 32,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Riwayat aktivitas dinas',
                  style: emphasizedTypeScale.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              AppTag(
                label: '${item.timeline.length} aktivitas',
                variant: AppTagVariant.secondary,
                size: AppTagSize.small,
              ),
            ],
          ),

          // ── Pemisah ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space150),
            child: AppDivider(),
          ),

          // ── Konten Linimasa ─────────────────────────────────────────────
          if (item.timeline.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.space200,
              ),
              child: Center(
                child: Text(
                  'Belum ada riwayat aktivitas dinas.',
                  style: theme.typeScale.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: item.timeline.length,
              itemBuilder: (context, index) {
                final isLast = index == item.timeline.length - 1;
                final journey = item.timeline[index];
                return _buildTimelineNode(
                  context: context,
                  journey: journey,
                  isFirst: index == 0,
                  isLast: isLast,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required BuildContext context,
    required DutyTimelineEntity journey,
    required bool isFirst,
    required bool isLast,
  }) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Indikator Node & Garis Alur Waktu ───────────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildNodeIndicator(context, isFirst: isFirst),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.hGap200,

          // ── Rincian Log Catatan ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.space200,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          journey.displayState,
                          style: emphasizedTypeScale.labelLarge.copyWith(
                            color: isFirst
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      AppSpacing.hGapSm,
                      AppTag(
                        label: journey.displayDuty,
                        variant:
                            journey.displayDutyTagVariant(isFirst: isFirst),
                        size: AppTagSize.small,
                      ),
                    ],
                  ),
                  AppSpacing.vGap25,
                  Text(
                    journey.displayTime,
                    style: typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (journey.journeyUid != null &&
                      journey.journeyUid!.isNotEmpty) ...[
                    AppSpacing.vGap50,
                    _buildTransactionUidChip(
                      context,
                      journey.journeyUid!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeIndicator(
    BuildContext context, {
    required bool isFirst,
  }) {
    final colorScheme = AppTheme.of(context).colorScheme;

    if (isFirst) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outline,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.outline,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildTransactionUidChip(BuildContext context, String uid) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return AppTooltip(
      message: 'Salin ID aktifitas',
      child: AppTappable.builder(
        semanticLabel: 'Salin ID aktifitas $uid',
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: uid));
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: 'ID aktifitas disalin ke papan klip.',
            );
          }
        },
        builder: (context, state) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: state.pressed
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerHigh,
              borderRadius: AppRadius.borderExtraSmall,
              border: state.focused
                  ? Border.all(
                      color: colorScheme.primary,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space100,
                vertical: AppSpacing.space50,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID: $uid',
                    style: typeScale.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.hGapXs,
                  AppSvgIcon(
                    KawaloVectors.copy,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
