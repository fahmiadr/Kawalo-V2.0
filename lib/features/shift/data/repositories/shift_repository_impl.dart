import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/shift/data/datasources/shift_remote_data_source.dart';
import 'package:kawalo_mobile/features/shift/data/mappers/shift_mapper.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_model.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_request_model.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  const ShiftRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ShiftRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  Future<Either<Failure, T>> _online<T>(Future<T> Function() call) async {
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
  Future<Either<Failure, List<ShiftEntity>>> getShifts() => _online(
    () async => ShiftMapper.toEntityList(await remoteDataSource.getShifts()),
  );

  @override
  Future<Either<Failure, ShiftEntity>> createShift(ShiftInput input) => _online(
    () async => _entity(
      await remoteDataSource.createShift(ShiftRequestModel.fromInput(input)),
    ),
  );

  @override
  Future<Either<Failure, ShiftEntity>> updateShift(
    String uid,
    ShiftInput input,
  ) => _online(
    () async => _entity(
      await remoteDataSource.updateShift(
        uid,
        ShiftRequestModel.fromInput(input),
      ),
    ),
  );

  @override
  Future<Either<Failure, void>> deleteShift(String uid) =>
      _online(() => remoteDataSource.deleteShift(uid));

  ShiftEntity _entity(ShiftModel model) {
    final entity = ShiftMapper.toEntity(model);
    if (entity == null) {
      throw const ServerException('Respons shift dari server tidak valid.');
    }
    return entity;
  }
}
