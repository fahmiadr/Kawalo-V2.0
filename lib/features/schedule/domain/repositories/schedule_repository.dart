import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';

abstract interface class ScheduleRepository {
  /// Shifts of the signed-in user from [from] to [to] (inclusive), ordered by
  /// date and start time. Needs a connection: there is no offline cache.
  Future<Either<Failure, List<ScheduleEntity>>> getMySchedules({
    required DateTime from,
    required DateTime to,
  });
}
