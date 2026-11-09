import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/repositories/operational_repository_impl.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/usecases/get_operationals/get_operationals_usecase.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';

/// Feature Composition Root untuk modul Operasional pada Frontend.
///
/// Menerima dependensi bersama satu kali dan membangun
/// [OperationalRepository] satu kali untuk dipakai ulang oleh factory cubit.
final class OperationalModule {
  /// Membangun modul beserta [repository] tunggalnya.
  OperationalModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    SyncStorageService? syncStorageService,
  }) : _syncStorage = syncStorageService ?? SyncStorageService.singleton() {
    repository = OperationalRepositoryImpl(
      remoteDataSource: OperationalRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: OperationalLocalDataSourceImpl(isar: isar),
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;

  /// Repository operasional tunggal yang dipakai semua factory.
  late final OperationalRepository repository;

  /// Merakit dan mengembalikan instance [OperationalCubit] yang siap pakai.
  OperationalCubit createCubit() {
    return OperationalCubit(
      getOperationalsUseCase: GetOperationalsUseCase(repository),
      syncStorageService: _syncStorage,
    );
  }
}
