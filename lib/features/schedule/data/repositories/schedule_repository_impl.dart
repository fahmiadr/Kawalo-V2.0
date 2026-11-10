import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/data/mappers/schedule_mapper.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ScheduleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getMySchedules({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NoInternetFailure());
    }
    try {
      final models = await remoteDataSource.getMySchedules(from: from, to: to);
      return Right(ScheduleMapper.toEntityList(models));
    } on Exception catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
