import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_local_data_source.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_remote_data_source.dart';
import 'package:kawalo_mobile/features/information/data/repositories/information_repository_impl.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';

/// Feature Composition Root untuk modul Informasi / Feed pada Frontend.
///
/// Receives the shared dependencies once and builds a single
/// [InformationRepository] that every cubit factory reuses. Registered through
/// `RepositoryProvider` so the presentation layer never assembles dependencies
/// itself.
final class InformationModule implements CacheWipeableModule {
  InformationModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    SyncStorageService? syncStorageService,
    GroupRepository? groupRepository,
    LocationService? locationService,
  }) : _locationService = locationService ?? const DefaultLocationService(),
       _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
       _groupRepository =
           groupRepository ??
           GroupModule.createRepository(
             apiClient: apiClient,
             networkInfo: networkInfo,
           ) {
    final localDataSource = InformationLocalDataSourceImpl(isar: isar);
    cacheWipeable = localDataSource;
    repository = InformationRepositoryImpl(
      remoteDataSource: InformationRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: localDataSource,
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final LocationService _locationService;
  final SyncStorageService _syncStorage;
  final GroupRepository _groupRepository;
  late final InformationRepository repository;

  @override
  late final CacheWipeable cacheWipeable;

  /// Merakit dan mengembalikan instance [InformationCubit] yang siap pakai.
  InformationCubit createCubit() {
    return InformationCubit(
      informationRepository: repository,
      deleteInformationUseCase: DeleteInformationUseCase(repository),
      deleteBatchInformationUseCase: DeleteBatchInformationUseCase(repository),
      groupRepository: _groupRepository,
      syncStorageService: _syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [InformationFormCubit] yang siap
  /// pakai untuk operasi posting (tambah) maupun pembaruan (edit) informasi.
  InformationFormCubit createFormCubit({InformationItemEntity? initialItem}) {
    return InformationFormCubit(
      createInformationUseCase: CreateInformationUseCase(repository),
      updateInformationUseCase: UpdateInformationUseCase(repository),
      locationService: _locationService,
      initialItem: initialItem,
    );
  }
}
