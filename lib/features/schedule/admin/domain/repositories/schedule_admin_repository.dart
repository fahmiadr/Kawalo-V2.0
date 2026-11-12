import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';

/// Admin side of the group schedule. Online-only: there is no cache.
abstract interface class ScheduleAdminRepository {
  /// Schedules of the whole group from [from] to [to] inclusive (the server
  /// allows at most 62 days), optionally for one person.
  Future<Either<Failure, List<ManagedScheduleEntity>>> getSchedules({
    required DateTime from,
    required DateTime to,
    String? email,
  });

  Future<Either<Failure, List<ShiftOptionEntity>>> getShifts();

  /// 409 failures keep the server message and `statusCode`.
  Future<Either<Failure, Unit>> create(
    ScheduleEntry entry, {
    bool overwrite = false,
  });

  Future<Either<Failure, BulkScheduleResult>> createBulk(
    List<ScheduleEntry> entries, {
    bool overwrite = false,
  });

  Future<Either<Failure, Unit>> update(String id, ScheduleEntry entry);

  Future<Either<Failure, DeleteSchedulesResult>> deleteMany(List<String> ids);
}
