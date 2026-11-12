import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/extensions/managed_schedule_ui_extension.dart';

const _weekdayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Month grid (Monday first) with one dot per shift scheduled that day.
/// Past days are dimmed because their schedules are locked.
class ScheduleAdminCalendar extends StatelessWidget {
  const ScheduleAdminCalendar({
    required this.state,
    required this.today,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDay,
    super.key,
  });

  final ScheduleAdminState state;
  final DateTime today;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final month = state.month;
    final start = gridStart(month);
    final end = gridEnd(month);
    final days = <DateTime>[
      for (
        var d = start;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AppIconButton(
              semanticLabel: 'Bulan sebelumnya',
              onPressed: onPreviousMonth,
              icon: const AppSvgIcon(KawaloVectors.arrowLeft02, size: 24),
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  '${monthNames[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            AppIconButton(
              semanticLabel: 'Bulan berikutnya',
              onPressed: onNextMonth,
              icon: const AppSvgIcon(KawaloVectors.arrowRight01, size: 24),
            ),
            AppSpacing.hGapSm,
            AppChip(label: 'Hari ini', onPressed: onToday),
          ],
        ),
        AppSpacing.vGapSm,
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.typeScale.labelMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.vGap50,
        for (var row = 0; row < days.length; row += 7)
          Row(
            children: [
              for (final day in days.sublist(row, row + 7))
                Expanded(
                  child: _DayCell(
                    day: day,
                    inMonth: day.month == month.month,
                    isPast: day.isBefore(today),
                    isToday: day == today,
                    isSelected: day == state.selectedDay,
                    colors: state.shiftColorsOn(day),
                    onTap: () => onSelectDay(day),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isPast,
    required this.isToday,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isPast;
  final bool isToday;
  final bool isSelected;
  final List<String?> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final dimmed = !inMonth || isPast;
    final numberColor = isSelected
        ? colorScheme.onPrimary
        : dimmed
        ? colorScheme.onSurface.withValues(alpha: 0.5)
        : colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${day.day} ${monthNames[day.month - 1]}'
          '${isToday ? ', hari ini' : ''}, ${colors.length} shift',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStateLayer.minTouchTarget,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : null,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '${day.day}',
                    style: theme.typeScale.bodyMedium.copyWith(
                      color: numberColor,
                      fontWeight: isToday ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                AppSpacing.vGap25,
                SizedBox(
                  height: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final c in colors.take(3))
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: parseShiftColor(c) ?? colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
