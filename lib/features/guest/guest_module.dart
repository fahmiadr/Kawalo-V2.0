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
/// Bertanggung jawab atas inisialisasi dan perakitan Dependency Injection
/// (DataSources -> Repository -> UseCases -> Cubit) di tingkat fitur,
/// selaras dengan pola modular Clean Architecture.
abstract final class GuestModule {
  /// Merakit dan mengembalikan instance [GuestCubit] yang siap pakai.
  static GuestCubit createCubit({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
    GetGroupMembersUseCase? getGroupMembersUseCase,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    final getGuestsUseCase = GetGuestsUseCase(repository);
    final deleteGuestUseCase = DeleteGuestUseCase(repository);
    final deleteBatchGuestUseCase = DeleteBatchGuestUseCase(repository);
    final checkoutGuestUseCase = CheckoutGuestUseCase(repository);
    final effectiveGetGroupMembersUseCase = getGroupMembersUseCase ??
        GroupModule.createGetGroupMembersUseCase(
          apiClient: apiClient,
          networkInfo: effectiveNetworkInfo,
        );

    return GuestCubit(
      getGuestsUseCase: getGuestsUseCase,
      deleteGuestUseCase: deleteGuestUseCase,
      deleteBatchGuestUseCase: deleteBatchGuestUseCase,
      checkoutGuestUseCase: checkoutGuestUseCase,
      getGroupMembersUseCase: effectiveGetGroupMembersUseCase,
      syncStorageService: syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [DeleteGuestUseCase] yang siap pakai.
  static DeleteGuestUseCase createDeleteUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return DeleteGuestUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [DeleteBatchGuestUseCase] yang siap
  /// pakai.
  static DeleteBatchGuestUseCase createDeleteBatchUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return DeleteBatchGuestUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [CreateGuestUseCase] yang siap pakai.
  static CreateGuestUseCase createCreateUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return CreateGuestUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [UpdateGuestUseCase] yang siap pakai.
  static UpdateGuestUseCase createUpdateUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return UpdateGuestUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [CheckoutGuestUseCase] yang siap pakai.
  static CheckoutGuestUseCase createCheckoutUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final guestLocalDataSource = GuestLocalDataSourceImpl(isar: isar);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: guestLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return CheckoutGuestUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [GuestFormCubit] yang siap pakai.
  static GuestFormCubit createGuestFormCubit({
    required ApiClient apiClient,
    Isar? isar,
    NetworkInfo? networkInfo,
    GetGroupMembersUseCase? getGroupMembersUseCase,
    GuestItemEntity? initialItem,
  }) {
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource = GuestRemoteDataSourceImpl(apiClient: apiClient);

    final repository = GuestRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource:
          isar != null ? GuestLocalDataSourceImpl(isar: isar) : null,
      networkInfo: effectiveNetworkInfo,
    );

    final createGuestUseCase = CreateGuestUseCase(repository);
    final updateGuestUseCase = UpdateGuestUseCase(repository);
    final getMasterTypesUseCase = GetMasterGuestTypesUseCase(repository);
    final effectiveGetGroupMembersUseCase = getGroupMembersUseCase ??
        GroupModule.createGetGroupMembersUseCase(
          apiClient: apiClient,
          networkInfo: effectiveNetworkInfo,
        );

    return GuestFormCubit(
      createGuestUseCase: createGuestUseCase,
      updateGuestUseCase: updateGuestUseCase,
      getMasterGuestTypesUseCase: getMasterTypesUseCase,
      getGroupMembersUseCase: effectiveGetGroupMembersUseCase,
      initialItem: initialItem,
    );
  }
}
