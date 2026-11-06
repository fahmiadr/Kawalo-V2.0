import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_local_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/datasources/operational_remote_data_source.dart';
import 'package:kawalo_mobile/features/operational/data/mappers/operational_mapper.dart';
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
    this.localDataSource,
    this.syncStorageService,
    this.networkInfo,
  });

  /// Sumber aktifitas operasional jarak jauh.
  final OperationalRemoteDataSource remoteDataSource;

  /// Sumber aktifitas operasional lokal untuk mode offline dan caching.
  final OperationalLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService? syncStorageService;

  /// Utilitas pengecekan konektivitas jaringan perangkat.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, OperationalResult>> getOperationals(
    GetOperationalsParams params,
  ) async {
    // 1. Guard Offline: Jika bukan refresh, dilarang memicu remote fetch jika
    // perangkat sedang offline. Langsung ambil dari local cache seketika.
    if (!params.isRefresh) {
      final isConnected =
          await (networkInfo?.isConnected ?? Future.value(true));
      if (!isConnected) {
        if (localDataSource != null) {
          final cached = await localDataSource!.getCachedOperationals(
            search: params.search,
            startDate: params.startDate,
            endDate: params.endDate,
          );
          return Right(
            OperationalResult(
              items: OperationalMapper.toEntityList(cached),
              isFromCache: true,
            ),
          );
        }
        return const Left(NoInternetFailure.offlineNoStorage());
      }
    }

    // 2. Mode Online atau Pull-to-Refresh: Lakukan remote fetch ke server
    // (pull-to-refresh selalu mencoba ke remote meskipun sedang offline).
    try {
      final query = OperationalQueryModel(
        search: params.search,
        limit: params.limit,
        offset: params.offset,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      final operational = await remoteDataSource.getOperationals(
        query: query,
        cancelToken: params.cancelToken,
      );

      // Simpan data ke cache lokal jika tersedia
      if (localDataSource != null && operational.isNotEmpty) {
        await localDataSource!.cacheOperationals(operational);

        // Terapkan Cache Invalidation & Eviction: Rolling Window 30 Hari
        final thirtyDaysAgo =
            DateTime.now().subtract(AppConstants.cacheRetentionDuration);
        await localDataSource!.deleteOlderThan(thirtyDaysAgo);
      }

      // Catat waktu sukses sinkronisasi server
      await (syncStorageService ?? SyncStorageService.singleton())
          .saveLastSync(AppConstants.syncKeyOperational, DateTime.now());

      return Right(
        OperationalResult(
          items: OperationalMapper.toEntityList(operational),
        ),
      );
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      if (localDataSource != null && _canFallbackToCache(e)) {
        final cached = await localDataSource!.getCachedOperationals(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
        );
        return Right(
          OperationalResult(
            items: OperationalMapper.toEntityList(cached),
            isFromCache: true,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      if (localDataSource != null) {
        final cached = await localDataSource!.getCachedOperationals(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
        );
        return Right(
          OperationalResult(
            items: OperationalMapper.toEntityList(cached),
            isFromCache: true,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }

  bool _canFallbackToCache(AppException e) {
    if (e is RequestCancelledException || e is AuthException) {
      return false;
    }
    return true;
  }
}
