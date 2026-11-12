import 'package:flutter/material.dart' show Color;
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';

const monthNames = [
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

extension ManagedScheduleUiExtension on ManagedScheduleEntity {
  Color? get shiftAccentColor => parseShiftColor(shiftColor);

  String get shiftLabel => shiftName ?? 'Shift dihapus';

  String? get timeRange =>
      startTime == null || endTime == null ? null : '$startTime-$endTime';

  /// "Masuk 07:04 (+4 mnt)" once attended, otherwise `null`.
  String? get attendanceLabel {
    final inTime = checkin;
    if (inTime == null) return null;
    return lateMins > 0 ? 'Masuk $inTime (+$lateMins mnt)' : 'Masuk $inTime';
  }
}

/// Schedules of one day grouped by shift, ordered by start time then name.
/// Rows whose shift no longer exists form their own group at the end.
List<ShiftGroup> groupByShift(List<ManagedScheduleEntity> items) {
  final groups = <String?, List<ManagedScheduleEntity>>{};
  for (final e in items) {
    groups.putIfAbsent(e.shiftUid, () => []).add(e);
  }
  final result =
      [
        for (final entry in groups.entries)
          ShiftGroup(
            shiftUid: entry.key,
            rows: [...entry.value]
              ..sort((a, b) => a.displayName.compareTo(b.displayName)),
          ),
      ]..sort((a, b) {
        if (a.shiftUid == null || b.shiftUid == null) {
          return a.shiftUid == null ? (b.shiftUid == null ? 0 : 1) : -1;
        }
        final byStart = (a.first.startTime ?? '').compareTo(
          b.first.startTime ?? '',
        );
        return byStart != 0
            ? byStart
            : a.first.shiftLabel.compareTo(b.first.shiftLabel);
      });
  return result;
}

class ShiftGroup {
  const ShiftGroup({required this.shiftUid, required this.rows});

  final String? shiftUid;
  final List<ManagedScheduleEntity> rows;

  ManagedScheduleEntity get first => rows.first;
}
