import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/extensions/attendance_item_ui_extension.dart';

/// Small dot in the shift colour, drawn next to the shift text. It is purely
/// decorative (the shift name is always written out) and renders nothing when
/// the shift has no usable colour.
class AttendanceShiftMarker extends StatelessWidget {
  /// Creates an [AttendanceShiftMarker].
  const AttendanceShiftMarker({required this.item, super.key});

  /// Attendance whose shift colour is shown.
  final AttendanceItemEntity item;

  @override
  Widget build(BuildContext context) {
    final color = item.shiftAccentColor;
    if (color == null) return const SizedBox.shrink();

    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('attendance_shift_marker'),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
