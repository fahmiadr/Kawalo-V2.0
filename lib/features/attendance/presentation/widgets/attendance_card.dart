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
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';

/// Komponen kartu daftar absensi mandiri, ramping, dan scannable.
///
/// Menyajikan informasi absensi personil dalam 3 baris detail esensial
/// tanpa data redundan, dengan penanda visual status kehadiran
/// dan indikator keterlambatan.
class AttendanceCard extends StatelessWidget {
  /// Membuat instance [AttendanceCard].
  const AttendanceCard({
    required this.item,
    super.key,
    this.onTap,
  });

  /// Data catatan absensi yang ditampilkan.
  final AttendanceItemEntity item;

  /// Callback ketika kartu ditekan.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final semanticLabel = 'Absensi ${item.displayUserName}, '
        'email ${item.displayUserEmail}, '
        'status ${item.displayCategory}, '
        'shift ${item.displayShift}, '
        'pos ${item.displayLocationName}, '
        'waktu ${item.displayAttendanceDt}, '
        'keterangan ${item.displayDiffLabel}';

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
          // ── Header: Avatar, Nama, & Email ────────────────────────
          Row(
            children: [
              _buildAvatar(context),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.displayUserName,
                      style: emphasizedTypeScale.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

          // ── Tag Status Absensi ────────────────────────────────────
          AppTag(
            label: item.displayCategory,
            variant: item.tagVariant,
          ),

          // ── Garis Pemisah (AppDivider) ────────────────────────────
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // ── Detail Informasi Absensi ──────────────────────────────
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.timeRotation,
            text: item.displayShift,
          ),
          AppSpacing.vGap50,
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.location1,
            text: item.displayLocationName,
          ),
          AppSpacing.vGap50,
          _buildTimestampAndStatusRow(
            context: context,
          ),
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

    final statusVariant =
        item.isLate ? AppTagVariant.error : AppTagVariant.primary;

    return Row(
      children: [
        const AppSvgIcon.color(
          KawaloColorVectors.calendar1,
          size: 20,
        ),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            item.displayAttendanceDt,
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.hGapSm,
        AppTag(
          label: item.displayDiffLabel,
          variant: statusVariant,
          size: AppTagSize.small,
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final pic = item.userProfilePic;
    final isNetworkUrl = pic != null &&
        (pic.startsWith('http://') || pic.startsWith('https://'));

    if (isNetworkUrl) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: CachedNetworkImage(
          imageUrl: pic,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildAvatarFallback(),
          errorWidget: (_, __, ___) => _buildAvatarFallback(),
        ),
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(
        KawaloColorVectors.patrol3,
        size: 40,
      ),
    );
  }
}
