import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';

/// Operasi cache lokal sebuah fitur, dibungkus agar penanganan data source
/// lokal yang opsional (nullable) terpusat: repositori cukup meneruskan
/// `null` bila tidak ada cache.
class CacheOps<M> {
  /// Membuat instance [CacheOps].
  const CacheOps({
    required this.read,
    required this.write,
    required this.deleteOlderThan,
  });

  /// Membaca data dari cache lokal sesuai filter permintaan.
  final Future<List<M>> Function() read;

  /// Menyimpan `models` ke cache lokal.
  final Future<void> Function(List<M> models) write;

  /// Menghapus data cache yang lebih lama dari ambang waktu.
  final Future<void> Function(DateTime threshold) deleteOlderThan;
}

/// Alur baku "remote dulu, fallback cache" untuk daftar.
///
/// 1. Bila bukan [isRefresh] dan perangkat offline: langsung dari cache
///    (atau gagal `offlineNoStorage` bila [cache] `null`).
/// 2. Ambil dari remote; bila berhasil dan tidak kosong, simpan ke cache
///    lalu hapus data lebih lama dari
///    [AppConstants.cacheRetentionDuration]; catat waktu sinkronisasi.
/// 3. Bila gagal: batal -> [RequestCancelledFailure]; selain itu fallback ke
///    cache bila tersedia (kecuali [AuthException]), jika tidak
///    kembalikan failure.
///
/// [toResult] memetakan model (remote maupun cache) ke hasil domain fitur.
Future<Either<Failure, R>> fetchRemoteWithCacheFallback<M, R>({
  required bool isRefresh,
  required NetworkInfo? networkInfo,
  required SyncStorageService? syncStorageService,
  required String syncKey,
  required Future<List<M>> Function() fetchRemote,
  required R Function(List<M> models, {required bool isFromCache}) toResult,
  required CacheOps<M>? cache,
}) async {
  Future<Either<Failure, R>> fromCache(CacheOps<M> ops) async => Right(
        toResult(await ops.read(), isFromCache: true),
      );

  // Pull-to-refresh selalu mencoba remote meskipun sedang offline.
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

    // Catat waktu sinkronisasi HANYA ketika remote berhasil.
    await (syncStorageService ?? SyncStorageService.singleton())
        .saveLastSync(syncKey, DateTime.now());

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
