import 'package:flutter/material.dart' show Color;
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';

extension ScheduleUiExtension on ScheduleEntity {
  Color? get shiftAccentColor => parseShiftColor(shiftColor);

  String get displayTimeRange => '$startTime-$endTime';

  /// Moment the shift ends; an end not after the start rolls to the next day
  /// (night shift).
  DateTime get endsAt {
    final hour = int.parse(endTime.substring(0, 2));
    final minute = int.parse(endTime.substring(3, 5));
    final nextDay = endTime.compareTo(startTime) <= 0 ? 1 : 0;
    return DateTime(date.year, date.month, date.day + nextDay, hour, minute);
  }
}

/// "Hari ini" / "Besok" for the two nearest calendar days, otherwise `null`.
String? relativeDayLabel(DateTime date, DateTime now) {
  final days = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return switch (days) {
    0 => 'Hari ini',
    1 => 'Besok',
    _ => null,
  };
}

/// Subtitle of the Beranda shortcut: the first shift that has not ended yet,
/// e.g. "Hari ini · 08:00-16:00", or "Belum ada jadwal". [schedules] must be
/// ordered by date and start time.
String nextShiftSubtitle(List<ScheduleEntity> schedules, DateTime now) {
  for (final schedule in schedules) {
    if (!schedule.endsAt.isAfter(now)) continue;
    final day =
        relativeDayLabel(schedule.date, now) ??
        AppDateFormat.formatDayMonth(schedule.date);
    return '$day · ${schedule.displayTimeRange}';
  }
  return 'Belum ada jadwal';
}
