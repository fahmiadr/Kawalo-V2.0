import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/forecast/data/datasources/forecast_remote_data_source.dart';
import 'package:kawalo_mobile/features/forecast/data/mappers/forecast_mapper.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_option_models.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_request_model.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/repositories/forecast_repository.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';

class ForecastRepositoryImpl implements ForecastRepository {
  const ForecastRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ForecastRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

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
  Future<Either<Failure, ForecastOptions>> loadOptions() => _guard(() async {
    // Record `.wait` would wrap a failure in ParallelWaitError, which the
    // guard (and the failure mapping) does not understand.
    final results = await Future.wait<Object>([
      remoteDataSource.getShifts(),
      remoteDataSource.getMembers(),
    ]);
    return ForecastMapper.toOptions(
      results[0] as List<ForecastShiftModel>,
      results[1] as List<ForecastMemberModel>,
    );
  });

  @override
  Future<Either<Failure, ForecastPreview>> preview(
    ForecastConfig config, {
    int? seed,
  }) => _guard(() async {
    final model = await remoteDataSource.preview(
      ForecastRequestModel(config: config, seed: seed),
    );
    return ForecastMapper.toPreview(model);
  });

  @override
  Future<Either<Failure, ForecastResult>> apply(
    ForecastConfig config, {
    required ForecastPreview preview,
    required bool confirmOverwrite,
  }) => _guard(() async {
    final model = await remoteDataSource.commit(
      ForecastRequestModel(
        config: config,
        seed: preview.seed,
        previewToken: preview.token,
        confirmOverwrite: confirmOverwrite,
      ),
    );
    return ForecastMapper.toResult(model);
  });
}
