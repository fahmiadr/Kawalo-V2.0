import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/extensions/schedule_ui_extension.dart';

/// One shift row of "Jadwal Saya": day label, shift line and time range.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({required this.schedule, required this.now, super.key});

  final ScheduleEntity schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final accent = schedule.shiftAccentColor;
    final day = scheduleDayLabel(schedule.date, now);

    return Semantics(
      container: true,
      label: '$day, ${schedule.displayShiftLine}, ${schedule.displayTimeRange}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tones.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tones.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tones.pat.soft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: tones.pat.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tones.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    schedule.displayShiftLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tones.ink2, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (accent != null) ...[
              Container(
                key: const ValueKey('schedule_shift_marker'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: tones.line),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              schedule.displayTimeRange,
              style: AppTheme.monoFigures.copyWith(
                color: tones.ink2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
