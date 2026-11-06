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
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_batch_information/delete_batch_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/delete_information/delete_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/get_information/get_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';

/// Feature Composition Root untuk modul Informasi / Feed pada Frontend.
///
/// Bertanggung jawab atas inisialisasi dan perakitan Dependency Injection
/// (DataSources -> Repository -> UseCases -> Cubit) di tingkat fitur,
/// selaras dengan pola modular Clean Architecture.
abstract final class InformationModule {
  /// Merakit dan mengembalikan instance [InformationCubit] yang siap pakai.
  static InformationCubit createCubit({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
    GetGroupMembersUseCase? getGroupMembersUseCase,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    final getInformationUseCase = GetInformationUseCase(repository);
    final deleteUseCase = DeleteInformationUseCase(repository);
    final deleteBatchUseCase = DeleteBatchInformationUseCase(repository);
    final effectiveGetGroupMembersUseCase = getGroupMembersUseCase ??
        GroupModule.createGetGroupMembersUseCase(
          apiClient: apiClient,
          networkInfo: effectiveNetworkInfo,
        );

    return InformationCubit(
      getInformationUseCase: getInformationUseCase,
      deleteInformationUseCase: deleteUseCase,
      deleteBatchInformationUseCase: deleteBatchUseCase,
      getGroupMembersUseCase: effectiveGetGroupMembersUseCase,
      syncStorageService: syncStorage,
    );
  }

  /// Merakit dan mengembalikan instance [DeleteInformationUseCase] yang siap
  /// pakai.
  static DeleteInformationUseCase createDeleteUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return DeleteInformationUseCase(repository);
  }

  /// Merakit dan mengembalikan instance
  /// [DeleteBatchInformationUseCase] yang siap pakai.
  static DeleteBatchInformationUseCase createDeleteBatchUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return DeleteBatchInformationUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [CreateInformationUseCase] yang siap
  /// pakai.
  static CreateInformationUseCase createCreateUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return CreateInformationUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [UpdateInformationUseCase] yang siap
  /// pakai.
  static UpdateInformationUseCase createUpdateUseCase({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return UpdateInformationUseCase(repository);
  }

  /// Merakit dan mengembalikan instance [InformationFormCubit] yang siap
  /// pakai untuk operasi posting (tambah) maupun pembaruan (edit) informasi.
  static InformationFormCubit createFormCubit({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
    InformationItemEntity? initialItem,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        InformationRemoteDataSourceImpl(apiClient: apiClient);

    final informationLocalDataSource = InformationLocalDataSourceImpl(
      isar: isar,
    );

    final repository = InformationRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: informationLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    return InformationFormCubit(
      createInformationUseCase: CreateInformationUseCase(repository),
      updateInformationUseCase: UpdateInformationUseCase(repository),
      initialItem: initialItem,
    );
  }
}
