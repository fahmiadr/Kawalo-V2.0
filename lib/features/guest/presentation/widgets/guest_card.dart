import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';

/// Komponen kartu untuk menampilkan informasi data tamu secara ringkas.
///
/// Mematuhi spesifikasi Material 3 Expressive, token tema sistem Kawalo,
/// serta standar aksesibilitas WCAG 2.1/2.2 AA.
class GuestCard extends StatelessWidget {
  /// Membuat instance [GuestCard].
  const GuestCard({
    required this.item,
    super.key,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isSelectable = true,
  });

  /// Data tamu yang ditampilkan pada kartu.
  final GuestItemEntity item;

  /// Callback ketika kartu ditekan.
  final VoidCallback? onTap;

  /// Callback ketika kartu ditekan lama (long press).
  final VoidCallback? onLongPress;

  /// Apakah kartu sedang berada dalam mode seleksi multi-item.
  final bool isSelectionMode;

  /// Status apakah kartu ini sedang dalam kondisi terpilih.
  final bool isSelected;

  /// Status apakah kartu ini berhak dipilih oleh pengguna aktif.
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final selectedInfo = isSelected ? ', terpilih' : '';
    final semanticLabel =
        'Data tamu ${item.displayName}, jenis ${item.displayGuestType}, '
        'identitas ${item.displayIdentityType}, '
        'tujuan ${item.displayDestination}, '
        'keperluan ${item.displayPurpose}, '
        'status terakhir ${item.latestStatusLabel}, '
        'waktu status terakhir ${item.latestStatusTime}$selectedInfo';

    final effectiveCard = AppCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      color: isSelected ? colorScheme.surfaceContainerHighest : null,
      border: isSelected
          ? BorderSide(color: colorScheme.primary, width: 2)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar / Checkbox, Nama, Jenis/Tipe & Chevron ─────────
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
                            item.displayName,
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
                      '${item.displayGuestType} • ${item.displayIdentityType}',
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

          // ── Tag Kategori Tamu ───────────────────────────────────────────
          AppTag(label: item.displayCategory, variant: AppTagVariant.secondary),

          // ── Garis Pemisah (AppDivider) ───────────────────────────────────
          const Padding(
            padding: AppSpacing.paddingVertical150,
            child: AppDivider(),
          ),

          // ── Detail Informasi Tamu ───────────────────────────────────────
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.location1,
            text: item.displayDestination,
          ),
          AppSpacing.vGap50,
          _buildDetailRow(
            context: context,
            iconPath: KawaloColorVectors.fileEdit,
            text: item.displayPurpose,
          ),
          AppSpacing.vGap50,
          _buildTimestampAndStatusRow(context: context),
        ],
      ),
    );

    if (isSelectionMode && !isSelectable) {
      return Opacity(
        opacity: AppStateLayer.disabledOpacity,
        child: effectiveCard,
      );
    }

    return effectiveCard;
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    if (isSelectionMode) {
      if (!isSelectable) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Center(
            child: AppSvgIcon(
              KawaloVectors.squareLock01,
              size: 24,
              color: colorScheme.outline,
            ),
          ),
        );
      }

      return AppSelectionLeading(
        selected: isSelected,
        selectedChild: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: AppRadius.borderMedium,
          ),
          child: Center(
            child: AppSvgIcon(
              KawaloVectors.check,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
        ),
        child: _buildDefaultAvatar(context),
      );
    }

    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return const ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: AppSvgIcon.color(KawaloColorVectors.cardTag2, size: 40),
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

  Widget _buildTimestampAndStatusRow({required BuildContext context}) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final AppTagVariant statusVariant;
    if (item.latestStatusLabel == 'Keluar') {
      statusVariant = AppTagVariant.primary;
    } else if (item.latestStatusLabel == 'Konfirmasi') {
      statusVariant = AppTagVariant.secondary;
    } else {
      statusVariant = AppTagVariant.tertiary;
    }

    return Row(
      children: [
        const AppSvgIcon.color(KawaloColorVectors.timeRotation, size: 20),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            'Status terakhir: ${item.latestStatusTime}',
            style: typeScale.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.hGapSm,
        AppTag(
          label: item.latestStatusLabel,
          variant: statusVariant,
          size: AppTagSize.small,
        ),
      ],
    );
  }
}
