import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/datasources/schedule_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/repositories/schedule_admin_repository_impl.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/repositories/schedule_admin_repository.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:kawalo_mobile/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:kawalo_mobile/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';

/// Composition root of the work schedule feature (own schedule and the admin
/// management of the group schedule). Online-only, so unlike the cached modules
/// it has nothing to wipe on logout.
final class ScheduleModule {
  ScheduleModule({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) : repository = ScheduleRepositoryImpl(
         remoteDataSource: ScheduleRemoteDataSourceImpl(apiClient: apiClient),
         networkInfo: networkInfo,
       ),
       adminRepository = ScheduleAdminRepositoryImpl(
         remoteDataSource: ScheduleAdminRemoteDataSourceImpl(
           apiClient: apiClient,
         ),
         networkInfo: networkInfo,
       ),
       // Stateless, so building a second instance beside the one in `main.dart`
       // avoids a new constructor parameter.
       groupRepository = GroupModule.createRepository(
         apiClient: apiClient,
         networkInfo: networkInfo,
       );

  final ScheduleRepository repository;

  final ScheduleAdminRepository adminRepository;

  final GroupRepository groupRepository;

  ScheduleCubit createCubit() => ScheduleCubit(repository: repository);

  ScheduleAdminCubit createAdminCubit() =>
      ScheduleAdminCubit(repository: adminRepository);

  ScheduleFormCubit createFormCubit() => ScheduleFormCubit(
    repository: adminRepository,
    groupRepository: groupRepository,
  );
}
