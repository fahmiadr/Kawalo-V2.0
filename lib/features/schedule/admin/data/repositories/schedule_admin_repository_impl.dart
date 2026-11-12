import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/datasources/schedule_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/mappers/schedule_admin_mapper.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';

class ScheduleAdminRepositoryImpl implements ScheduleAdminRepository {
  const ScheduleAdminRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ScheduleAdminRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  /// Offline guard plus exception-to-failure mapping shared by every call.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return const Left(NoInternetFailure());
    }
    try {
      return Right(await call());
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ManagedScheduleEntity>>> getSchedules({
    required DateTime from,
    required DateTime to,
    String? email,
  }) => _guard(
    () async => ScheduleAdminMapper.toEntityList(
      await remoteDataSource.getSchedules(from: from, to: to, email: email),
    ),
  );

  @override
  Future<Either<Failure, List<ShiftOptionEntity>>> getShifts() => _guard(
    () async => (await remoteDataSource.getShifts())
        .map(ScheduleAdminMapper.toShift)
        .toList(growable: false),
  );

  @override
  Future<Either<Failure, Unit>> create(
    ScheduleEntry entry, {
    bool overwrite = false,
  }) => _guard(() async {
    await remoteDataSource.create(entry, overwrite: overwrite);
    return unit;
  });

  @override
  Future<Either<Failure, BulkScheduleResult>> createBulk(
    List<ScheduleEntry> entries, {
    bool overwrite = false,
  }) => _guard(
    () async => ScheduleAdminMapper.toBulk(
      await remoteDataSource.createBulk(entries, overwrite: overwrite),
    ),
  );

  @override
  Future<Either<Failure, Unit>> update(String id, ScheduleEntry entry) =>
      _guard(() async {
        await remoteDataSource.update(id, entry);
        return unit;
      });

  @override
  Future<Either<Failure, DeleteSchedulesResult>> deleteMany(List<String> ids) =>
      _guard(
        () async => ScheduleAdminMapper.toDelete(
          await remoteDataSource.deleteMany(ids),
        ),
      );
}
