import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/repositories/cached_remote_fetch.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/mappers/operational_mapper.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_query_model.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';

/// Implementasi konkret dari [OperationalRepository] yang berkomunikasi
/// dengan remote data source dan mengelola fallback cache lokal saat offline.
///
/// Selaras 100% dengan kontrak endpoint backend `GET /v1/operational`
/// (`GetOperationalQueryDto`).
class OperationalRepositoryImpl implements OperationalRepository {
  /// Membuat instance [OperationalRepositoryImpl].
  const OperationalRepositoryImpl({
    required this.remoteDataSource,
    required this.syncStorageService,
    this.localDataSource,
    this.networkInfo,
  });

  /// Sumber aktivitas operasional jarak jauh.
  final OperationalRemoteDataSource remoteDataSource;

  /// Sumber aktivitas operasional lokal untuk mode offline dan caching.
  final OperationalLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService syncStorageService;

  /// Utilitas pengecekan konektivitas jaringan perangkat.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, OperationalResult>> getOperationals(
    GetOperationalsParams params,
  ) {
    final local = localDataSource;
    return fetchRemoteWithCacheFallback<OperationalModel, OperationalResult>(
      isRefresh: params.isRefresh,
      networkInfo: networkInfo,
      syncStorageService: syncStorageService,
      syncKey: AppConstants.syncKeyOperational,
      fetchRemote: () => remoteDataSource.getOperationals(
        query: OperationalQueryModel(
          search: params.search,
          limit: params.limit,
          offset: params.offset,
          startDate: params.startDate,
          endDate: params.endDate,
        ),
        cancelToken: params.cancelToken,
      ),
      toResult: (models, {required isFromCache}) => OperationalResult(
        items: OperationalMapper.toEntityList(models),
        isFromCache: isFromCache,
      ),
      cache: local == null
          ? null
          : CacheOps(
              read: () => local.getCachedOperationals(
                search: params.search,
                startDate: params.startDate,
                endDate: params.endDate,
              ),
              write: local.cacheOperationals,
              deleteOlderThan: local.deleteOlderThan,
            ),
    );
  }
}
