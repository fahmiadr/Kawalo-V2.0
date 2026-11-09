import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';

/// Local cache operations of a feature, wrapped so the handling of an optional
/// (nullable) local data source stays in one place: a repository simply passes
/// `null` when it has no cache.
class CacheOps<M> {
  const CacheOps({
    required this.read,
    required this.write,
    required this.deleteOlderThan,
  });

  final Future<List<M>> Function() read;

  final Future<void> Function(List<M> models) write;

  final Future<void> Function(DateTime threshold) deleteOlderThan;
}

/// Runs [op] (cache sync after a successful remote mutation) on a best-effort
/// basis: `null` means there is no cache, and a cache I/O failure must not undo
/// the success already confirmed by the authoritative server.
Future<void> bestEffortCache(Future<void> Function()? op) async {
  if (op == null) return;
  try {
    await op();
  } on Object catch (_) {
    // Intentionally ignored, see the documentation above.
  }
}

/// Standard "remote first, cache fallback" flow for lists.
///
/// 1. When not [isRefresh] and the device is offline: serve from the cache (or
///   fail with `offlineNoStorage` when [cache] is `null`).
/// 2. Fetch from remote; on a non-empty success, write to the cache, evict data
///   older than [AppConstants.cacheRetentionDuration] and record the sync time.
/// 3. On failure: cancelled -> [RequestCancelledFailure]; otherwise fall back
///   to the cache when available (except for [AuthException]), else return the
///   failure.
///
/// [toResult] maps models (remote or cached) to the feature's domain result.
Future<Either<Failure, R>> fetchRemoteWithCacheFallback<M, R>({
  required bool isRefresh,
  required NetworkInfo? networkInfo,
  required SyncStorageService syncStorageService,
  required String syncKey,
  required Future<List<M>> Function() fetchRemote,
  required R Function(List<M> models, {required bool isFromCache}) toResult,
  required CacheOps<M>? cache,
}) async {
  Future<Either<Failure, R>> fromCache(CacheOps<M> ops) async =>
      Right(toResult(await ops.read(), isFromCache: true));

  // Pull-to-refresh always tries the remote, even while offline.
  if (!isRefresh) {
    final isConnected = await (networkInfo?.isConnected ?? Future.value(true));
    if (!isConnected) {
      if (cache != null) return await fromCache(cache);
      return const Left(NoInternetFailure.offlineNoStorage());
    }
  }

  try {
    final models = await fetchRemote();

    if (cache != null && models.isNotEmpty) {
      await cache.write(models);
      await cache.deleteOlderThan(
        DateTime.now().subtract(AppConstants.cacheRetentionDuration),
      );
    }

    // Record the sync time ONLY when the remote call succeeds.
    await syncStorageService.saveLastSync(syncKey, DateTime.now());

    return Right(toResult(models, isFromCache: false));
  } on AppException catch (e) {
    if (e is RequestCancelledException) {
      return const Left(RequestCancelledFailure());
    }
    if (cache != null && e is! AuthException) return await fromCache(cache);
    return Left(NetworkErrorHandler.handleExceptionToFailure(e));
  } on Exception catch (e) {
    if (cache != null) return await fromCache(cache);
    return Left(NetworkErrorHandler.handleExceptionToFailure(e));
  }
}
