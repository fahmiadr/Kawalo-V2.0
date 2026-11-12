import 'package:flutter/material.dart' show Color;
import 'package:kawalo_mobile/core/utils/shift_color.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';

/// "8 jam", "8 jam 30 menit", "45 menit".
String formatShiftDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest menit';
  return rest == 0 ? '$hours jam' : '$hours jam $rest menit';
}

/// "25 m", "100 m", "1 km".
String formatShiftRadius(int metres) => metres == 1000 ? '1 km' : '$metres m';

extension ShiftUiExtension on ShiftEntity {
  /// `null` for an empty or purple legacy colour.
  Color? get accentColor => parseShiftColor(color);

  String get displayTimeRange => '$startTime–$endTime';

  String get displaySchedule =>
      '$displayTimeRange · ${formatShiftDuration(durationMinutes)}';
}
