import 'package:kawalo_mobile/core/utils/app_sanitizer.dart';
import 'package:kawalo_mobile/features/schedule/data/models/schedule_model.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';

abstract final class ScheduleMapper {
  static final _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _hhmm = RegExp(r'^\d{2}:\d{2}$');

  /// `null` when the row cannot be shown: unparsable date or time. The
  /// timestamp comparison in the UI depends on strict `YYYY-MM-DD` / `HH:MM`.
  static ScheduleEntity? toEntity(ScheduleModel model) {
    final dateRaw = model.date.trim();
    final start = model.startTime?.trim();
    final end = model.endTime?.trim();
    if (!_dateOnly.hasMatch(dateRaw)) return null;
    if (start == null || end == null) return null;
    if (!_hhmm.hasMatch(start) || !_hhmm.hasMatch(end)) return null;

    final date = DateTime.tryParse(dateRaw);
    if (date == null || date.toIso8601String().substring(0, 10) != dateRaw) {
      return null;
    }

    return ScheduleEntity(
      id: model.id.trim(),
      date: date,
      shiftName: AppSanitizer.cleanString(model.shiftName) ?? 'Shift',
      startTime: start,
      endTime: end,
      shiftColor: AppSanitizer.cleanString(model.shiftColor),
      locationName: AppSanitizer.cleanString(model.locationName),
    );
  }

  /// Drops unusable rows and orders by date, then start time.
  static List<ScheduleEntity> toEntityList(List<ScheduleModel> models) {
    final entities = models.map(toEntity).whereType<ScheduleEntity>().toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
      });
    return List.unmodifiable(entities);
  }
}
