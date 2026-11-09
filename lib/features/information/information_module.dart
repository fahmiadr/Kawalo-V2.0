import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_local_data_source.dart';
import 'package:kawalo_mobile/features/information/data/datasources/information_remote_data_source.dart';
import 'package:kawalo_mobile/features/information/data/repositories/information_repository_impl.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/repositories/information_repository.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/get_information/get_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';

/// Feature Composition Root untuk modul Informasi / Feed pada Frontend.
///
/// Receives the shared dependencies once and builds a single
/// [InformationRepository] that every cubit factory reuses. Registered through
/// `RepositoryProvider` so the presentation layer never assembles dependencies
/// itself.
final class InformationModule {
  InformationModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    SyncStorageService? syncStorageService,
    GetGroupMembersUseCase? getGroupMembersUseCase,
  }) : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
       _getGroupMembersUseCase =
           getGroupMembersUseCase ??
           GroupModule.createGetGroupMembersUseCase(
             apiClient: apiClient,
             networkInfo: networkInfo,
           ) {
    repository = InformationRepositoryImpl(
      remoteDataSource: InformationRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: InformationLocalDataSourceImpl(isar: isar),
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;
  final GetGroupMembersUseCase _getGroupMembersUseCase;
  late final InformationRepository repository;

  /// Merakit dan mengembalikan instance [InformationCubit] yang siap pakai.
  InformationCubit createCubit() {
    return InformationCubit(
      getInformationUseCase: GetInformationUseCase(repository),
      deleteInformationUseCase: DeleteInformationUseCase(repository),
      deleteBatchInformationUseCase: DeleteBatchInformationUseCase(repository),
      getGroupMembersUseCase: _getGroupMembersUseCase,
      syncStorageService: _syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [InformationFormCubit] yang siap
  /// pakai untuk operasi posting (tambah) maupun pembaruan (edit) informasi.
  InformationFormCubit createFormCubit({InformationItemEntity? initialItem}) {
    return InformationFormCubit(
      createInformationUseCase: CreateInformationUseCase(repository),
      updateInformationUseCase: UpdateInformationUseCase(repository),
      initialItem: initialItem,
    );
  }
}
