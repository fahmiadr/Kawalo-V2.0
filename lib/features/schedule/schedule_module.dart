import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:kawalo_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';

/// Composition root of the work schedule feature. Read-only and online-only,
/// so unlike the cached modules it has nothing to wipe on logout.
final class ScheduleModule {
  ScheduleModule({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) : repository = ScheduleRepositoryImpl(
         remoteDataSource: ScheduleRemoteDataSourceImpl(apiClient: apiClient),
         networkInfo: networkInfo,
       );

  final ScheduleRepository repository;

  ScheduleCubit createCubit() => ScheduleCubit(repository: repository);
}
