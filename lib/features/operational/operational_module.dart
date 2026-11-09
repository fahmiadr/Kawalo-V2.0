import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/repositories/operational_repository_impl.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';

/// Feature Composition Root untuk modul Operasional pada Frontend.
///
/// Receives the shared dependencies once and builds a single
/// [OperationalRepository] that every cubit factory reuses.
final class OperationalModule implements CacheWipeableModule {
  OperationalModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    required SyncStorageService syncStorageService,
  }) : _syncStorage = syncStorageService {
    final localDataSource = OperationalLocalDataSourceImpl(isar: isar);
    cacheWipeable = localDataSource;
    repository = OperationalRepositoryImpl(
      remoteDataSource: OperationalRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: localDataSource,
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;
  late final OperationalRepository repository;

  @override
  late final CacheWipeable cacheWipeable;

  /// Merakit dan mengembalikan instance [OperationalCubit] yang siap pakai.
  OperationalCubit createCubit() {
    return OperationalCubit(
      repository: repository,
      syncStorageService: _syncStorage,
    );
  }
}
