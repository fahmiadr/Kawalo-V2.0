import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/presentation/extensions/operational_item_ui_extension.dart';

/// Komponen kartu untuk menampilkan informasi ringkas personil operasional
/// dan tugas terkini.
///
/// Mematuhi spesifikasi Material 3 Expressive, token sistem Kawalo,
/// serta standar aksesibilitas WCAG 2.1/2.2 AA.
class OperationalCard extends StatelessWidget {
  /// Membuat instance [OperationalCard].
  const OperationalCard({required this.item, super.key, this.onTap});

  /// Data personil tenaga kerja operasional.
  final OperationalItemEntity item;

  /// Callback ketika kartu ditekan.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel =
        'Personil ${item.displayUserName}, '
        'email ${item.displayUserEmail}, '
        'status dinas ${item.displayLatestDuty}, '
        '${item.displayTotalActivities} aktivitas, '
        'mulai dinas ${item.displayFirstActivityTime}, '
        'waktu status terkini ${item.displayLatestStateTime}, '
        'status terkini ${item.displayLatestState}';

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
          // ── Header: Avatar, Nama, Email, & Chevron ───────────
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
                            item.displayUserName,
                            style: emphasizedTypeScale.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.hGapXs,
                        const AppSvgIcon(KawaloVectors.arrowRight01, size: 24),
                      ],
                    ),
                    Text(
                      item.displayUserEmail,
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

          // ── Tag Tugas Terkini ─────────────────────────────────
          AppTag(
            label: item.displayLatestDuty,
            variant: item.displayDutyTagVariant,
          ),

          // ── Garis Pemisah ────────────────────────────────────
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // ── Detail Total Aktivitas ───────────────────────────
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.filePointToPoint,
            text: '${item.displayTotalActivities} aktivitas',
          ),
          AppSpacing.vGap50,

          // ── Detail Aktivitas Pertama ─────────────────────────
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.calendar1,
            text: 'Mulai dinas: ${item.displayFirstActivityTime}',
          ),
          AppSpacing.vGap50,

          // ── Baris Waktu & Status Terkini ─────────────────────
          _buildTimestampAndStatusRow(context),
        ],
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
        AppSvgIcon.color(iconPath, size: 20),
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

  Widget _buildTimestampAndStatusRow(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Row(
      children: [
        const AppSvgIcon.color(KawaloColorVectors.timeRotation, size: 20),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            'Status terkini: ${item.displayLatestStateTime}',
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.hGapSm,
        AppTag(
          label: item.displayLatestState,
          variant: item.displayStateTagVariant,
          size: AppTagSize.small,
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pic = item.userProfilePic;
    final isNetworkUrl =
        pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: CachedNetworkImage(
          imageUrl: pic,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, _) => _buildAvatarFallback(),
          errorWidget: (_, _, _) => _buildAvatarFallback(),
        ),
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(KawaloColorVectors.patrol3, size: 40),
    );
  }
}
