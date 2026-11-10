import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({required this.schedule, super.key});

  final ScheduleEntity schedule;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = schedule.shiftAccentColor;
    final location = schedule.locationName;

    return AppCard(
      semanticLabel:
          '${schedule.shiftName}, ${schedule.displayTimeRange}'
          '${location == null ? '' : ', $location'}',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space200,
        vertical: AppSpacing.space150,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.shiftName,
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (accent != null) ...[
                AppSpacing.hGapSm,
                ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('schedule_shift_marker'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline),
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.vGap50,
          _DetailRow(
            iconPath: KawaloColorVectors.timeRotation,
            text: schedule.displayTimeRange,
          ),
          if (location != null) ...[
            AppSpacing.vGap50,
            _DetailRow(iconPath: KawaloColorVectors.location1, text: location),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.iconPath, required this.text});

  final String iconPath;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        AppSvgIcon.color(iconPath, size: 20),
        AppSpacing.hGapSm,
        Expanded(
          child: Text(
            text,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
