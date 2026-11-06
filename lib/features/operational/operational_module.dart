import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/repositories/operational_repository_impl.dart';
import 'package:kawalo_mobile/features/operational/domain/usecases/get_operationals/get_operationals_usecase.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';

/// Feature Composition Root untuk modul Operasional pada Frontend.
///
/// Bertanggung jawab atas inisialisasi dan perakitan Dependency Injection
/// (DataSources -> Repository -> UseCases -> Cubit) di tingkat fitur,
/// selaras dengan pola modular Clean Architecture.
abstract final class OperationalModule {
  /// Merakit dan mengembalikan instance [OperationalCubit] yang siap pakai.
  static OperationalCubit createCubit({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage = syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        OperationalRemoteDataSourceImpl(apiClient: apiClient);

    final operationalLocalDataSource = OperationalLocalDataSourceImpl(
      isar: isar,
    );

    final repository = OperationalRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: operationalLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    final useCase = GetOperationalsUseCase(repository);

    return OperationalCubit(
      getOperationalsUseCase: useCase,
      syncStorageService: syncStorage,
    );
  }
}
