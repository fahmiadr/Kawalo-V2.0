import 'package:kawalo_mobile/features/schedule/admin/data/models/schedule_admin_models.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';

abstract final class ScheduleAdminMapper {
  static ManagedScheduleEntity toEntity(ManagedScheduleModel m) {
    final parsed = DateTime.tryParse(m.date) ?? DateTime(1970);
    return ManagedScheduleEntity(
      id: m.id,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      email: m.email.trim().toLowerCase(),
      name: m.name.trim(),
      isMember: m.isMember,
      locked: m.locked,
      shiftUid: m.shiftUid,
      shiftName: m.shiftName,
      shiftColor: m.shiftColor,
      startTime: m.startTime,
      endTime: m.endTime,
      locationName: m.locationName,
      checkin: _attendance(m.checkin),
      checkout: _attendance(m.checkout),
      lateMins: m.lateMins,
      avatarUrl: m.avatarUrl,
    );
  }

  /// Legacy rows store `N/A` or an empty string when nobody attended.
  static String? _attendance(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty || t == 'N/A' ? null : t;
  }

  static List<ManagedScheduleEntity> toEntityList(
    List<ManagedScheduleModel> models,
  ) => models.map(toEntity).toList(growable: false);

  static ShiftOptionEntity toShift(ShiftOptionModel m) => ShiftOptionEntity(
    uid: m.uid,
    name: m.name,
    startTime: m.startTime,
    endTime: m.endTime,
    color: m.color,
    locationName: m.locationName,
  );

  static BulkScheduleResult toBulk(BulkScheduleResultModel m) =>
      BulkScheduleResult(
        created: m.created,
        replaced: m.replaced,
        skipped: m.skipped,
        skippedItems: m.skippedItems,
      );

  static DeleteSchedulesResult toDelete(DeleteSchedulesResultModel m) =>
      DeleteSchedulesResult(
        deletedCount: m.deletedCount,
        skippedCount: m.skippedCount,
      );
}
