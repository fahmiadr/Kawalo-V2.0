import 'package:flutter/material.dart' show Color;
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';

extension ScheduleUiExtension on ScheduleEntity {
  Color? get shiftAccentColor => parseShiftColor(shiftColor);

  String get displayTimeRange => '$startTime-$endTime';

  /// An end not after the start means the shift ends the next day.
  bool get isOvernight => endTime.compareTo(startTime) <= 0;

  /// "Shift Pagi · Pos Utama · berakhir besok".
  String get displayShiftLine =>
      [shiftName, ?locationName, if (isOvernight) 'berakhir besok'].join(' · ');

  /// Moment the shift ends; an end not after the start rolls to the next day
  /// (night shift).
  DateTime get endsAt {
    final hour = int.parse(endTime.substring(0, 2));
    final minute = int.parse(endTime.substring(3, 5));
    final nextDay = isOvernight ? 1 : 0;
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

const scheduleWeekdayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "November 2026".
String scheduleMonthLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

/// "Hari ini · Jum 13", "Besok · Sab 14" or "Sen 16".
String scheduleDayLabel(DateTime date, DateTime now) {
  final day = '${scheduleWeekdayShort[date.weekday - 1]} ${date.day}';
  final relative = relativeDayLabel(date, now);
  return relative == null ? day : '$relative · $day';
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
