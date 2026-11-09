import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/group/domain/usecases/get_group_members/get_group_members_usecase.dart';
import 'package:kawalo_mobile/features/group/group_module.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_local_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/datasources/guest_remote_data_source.dart';
import 'package:kawalo_mobile/features/guest/data/repositories/guest_repository_impl.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/checkout_guest/checkout_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_guests/get_guests_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/get_master_guest_types/get_master_guest_types_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';

/// Feature Composition Root untuk modul Tamu pada Frontend.
///
/// Receives the shared dependencies once and builds a single [GuestRepository]
/// that every cubit factory reuses. Registered through `RepositoryProvider` so
/// the presentation layer never assembles dependencies itself.
final class GuestModule {
  GuestModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    SyncStorageService? syncStorageService,
    GetGroupMembersUseCase? getGroupMembersUseCase,
  })  : _syncStorage = syncStorageService ?? SyncStorageService.singleton(),
        _getGroupMembersUseCase = getGroupMembersUseCase ??
            GroupModule.createGetGroupMembersUseCase(
              apiClient: apiClient,
              networkInfo: networkInfo,
            ) {
    repository = GuestRepositoryImpl(
      remoteDataSource: GuestRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: GuestLocalDataSourceImpl(isar: isar),
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;
  final GetGroupMembersUseCase _getGroupMembersUseCase;
  late final GuestRepository repository;

  /// Merakit dan mengembalikan instance [GuestCubit] yang siap pakai.
  GuestCubit createCubit() {
    return GuestCubit(
      getGuestsUseCase: GetGuestsUseCase(repository),
      deleteGuestUseCase: DeleteGuestUseCase(repository),
      deleteBatchGuestUseCase: DeleteBatchGuestUseCase(repository),
      checkoutGuestUseCase: CheckoutGuestUseCase(repository),
      getGroupMembersUseCase: _getGroupMembersUseCase,
      syncStorageService: _syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [GuestFormCubit] yang siap pakai.
  GuestFormCubit createGuestFormCubit({GuestItemEntity? initialItem}) {
    return GuestFormCubit(
      createGuestUseCase: CreateGuestUseCase(repository),
      updateGuestUseCase: UpdateGuestUseCase(repository),
      getMasterGuestTypesUseCase: GetMasterGuestTypesUseCase(repository),
      getGroupMembersUseCase: _getGroupMembersUseCase,
      initialItem: initialItem,
    );
  }
}
