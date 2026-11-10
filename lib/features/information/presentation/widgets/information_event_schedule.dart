import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/extensions/information_item_ui_extension.dart';

/// "Jadwal acara" line of an EVENT feed. Renders nothing for other feed types
/// or when the schedule is empty.
class InformationEventSchedule extends StatelessWidget {
  /// Creates an [InformationEventSchedule].
  const InformationEventSchedule({required this.item, super.key});

  /// Feed whose schedule is shown.
  final InformationItemEntity item;

  @override
  Widget build(BuildContext context) {
    final schedule = item.eventScheduleLabel;
    if (schedule == null) return const SizedBox.shrink();

    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space100),
      child: Semantics(
        label: 'Jadwal acara $schedule',
        excludeSemantics: true,
        child: Row(
          children: [
            const AppSvgIcon.color(KawaloColorVectors.calendar1, size: 14),
            AppSpacing.hGapXs,
            Expanded(
              child: Text(
                'Jadwal acara: $schedule',
                style: theme.typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
