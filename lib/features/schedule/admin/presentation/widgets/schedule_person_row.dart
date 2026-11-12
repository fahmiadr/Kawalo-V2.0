import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/extensions/managed_schedule_ui_extension.dart';

/// Header of the people listed under one shift: colour marker, name, hours and
/// head count.
class ScheduleShiftHeader extends StatelessWidget {
  const ScheduleShiftHeader({required this.group, super.key});

  final ShiftGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final first = group.first;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space200),
      child: Row(
        children: [
          ShiftMarker(color: first.shiftAccentColor),
          AppSpacing.hGapSm,
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  text: first.shiftLabel,
                  style: theme.typography.emphasized.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    if (first.timeRange != null)
                      TextSpan(
                        text: '  ${first.timeRange}',
                        style: theme.typeScale.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          AppTag(
            label: '${group.rows.length} orang',
            variant: AppTagVariant.secondary,
            size: AppTagSize.small,
          ),
        ],
      ),
    );
  }
}

class ShiftMarker extends StatelessWidget {
  const ShiftMarker({required this.color, super.key});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color ?? colorScheme.outline,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline),
        ),
      ),
    );
  }
}

/// One person on a shift. Locked rows show a lock instead of a chevron and
/// cannot be ticked in selection mode.
class SchedulePersonRow extends StatelessWidget {
  const SchedulePersonRow({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final ManagedScheduleEntity item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;

  /// `null` when the viewer cannot manage the schedule.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final attendance = item.attendanceLabel;
    final status = !item.isMember
        ? 'Bukan anggota aktif'
        : attendance != null
        ? 'Sudah absen'
        : 'Belum absen';

    return AppCard(
      variant: AppCardVariant.outlined,
      onPressed: onTap,
      onLongPress: item.locked ? null : onLongPress,
      semanticLabel:
          '${item.displayName}, $status${item.locked ? ', terkunci' : ''}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space100,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppStateLayer.minTouchTarget,
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              if (item.locked)
                const AppSvgIcon(KawaloVectors.locked, size: 20)
              else
                ExcludeSemantics(
                  child: Checkbox(value: selected, onChanged: (_) => onTap()),
                ),
              AppSpacing.hGapSm,
            ],
            AppUserAvatar(
              name: item.displayName,
              imageUrl: item.avatarUrl,
              size: 36,
              maxInitials: 2,
              circle: true,
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.emphasized.bodyLarge.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.vGap25,
                  Row(
                    children: [
                      AppTag(
                        label: status,
                        size: AppTagSize.small,
                        variant: !item.isMember
                            ? AppTagVariant.error
                            : attendance != null
                            ? AppTagVariant.primary
                            : AppTagVariant.neutral,
                      ),
                      if (attendance != null) ...[
                        AppSpacing.hGapSm,
                        Flexible(
                          child: Text(
                            attendance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typeScale.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!selectionMode)
              AppSvgIcon(
                item.locked ? KawaloVectors.locked : KawaloVectors.arrowRight01,
                size: 20,
                color: colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}
