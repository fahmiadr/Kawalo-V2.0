import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/forecast/data/datasources/forecast_remote_data_source.dart';
import 'package:kawalo_mobile/features/forecast/data/repositories/forecast_repository_impl.dart';
import 'package:kawalo_mobile/features/forecast/domain/repositories/forecast_repository.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';

/// Composition root of the schedule forecast (admin). Online-only, so there is
/// nothing to wipe on logout.
final class ForecastModule {
  ForecastModule({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) : repository = ForecastRepositoryImpl(
         remoteDataSource: ForecastRemoteDataSourceImpl(apiClient: apiClient),
         networkInfo: networkInfo,
       );

  final ForecastRepository repository;

  ForecastCubit createCubit() => ForecastCubit(repository: repository);
}
