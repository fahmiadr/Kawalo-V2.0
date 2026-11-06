import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_query_model.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/attendance_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';

/// Implementasi konkret dari [AttendanceRepository] yang berkomunikasi
/// dengan remote data source dan mengelola fallback cache lokal saat offline.
///
/// Selaras dengan kontrak endpoint backend `GET /api/v1/attendance`
/// (`GetAttendanceQueryDto`).
class AttendanceRepositoryImpl implements AttendanceRepository {
  /// Membuat instance [AttendanceRepositoryImpl].
  const AttendanceRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
    this.syncStorageService,
    this.networkInfo,
  });

  /// Sumber data absensi jarak jauh.
  final AttendanceRemoteDataSource remoteDataSource;

  /// Sumber data absensi lokal untuk mode offline dan caching.
  final AttendanceLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService? syncStorageService;

  /// Layanan pengecekan status konektivitas jaringan.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, AttendanceResult>> getAttendances(
    GetAttendancesParams params,
  ) async {
    // 1. Guard Offline: Jika bukan refresh, dilarang memicu remote fetch jika
    // perangkat sedang offline. Langsung ambil dari local cache seketika.
    if (!params.isRefresh) {
      final isConnected =
          await (networkInfo?.isConnected ?? Future.value(true));
      if (!isConnected) {
        if (localDataSource != null) {
          final cached = await localDataSource!.getCachedAttendances(
            search: params.search,
            startDate: params.startDate,
            endDate: params.endDate,
          );
          return Right(
            AttendanceResult(
              items: AttendanceMapper.toEntityList(cached),
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
      final query = AttendanceQueryModel(
        search: params.search,
        limit: params.limit,
        offset: params.offset,
        startDate: params.startDate,
        endDate: params.endDate,
      );

      final attendance = await remoteDataSource.getAttendances(
        query: query,
        cancelToken: params.cancelToken,
      );

      // Simpan data ke cache lokal jika tersedia
      if (localDataSource != null && attendance.isNotEmpty) {
        await localDataSource!.cacheAttendances(attendance);

        // Terapkan Cache Invalidation & Eviction: Rolling Window 30 Hari
        final thirtyDaysAgo =
            DateTime.now().subtract(AppConstants.cacheRetentionDuration);
        await localDataSource!.deleteOlderThan(thirtyDaysAgo);
      }

      // Catat waktu sukses sinkronisasi server HANYA ketika remote berhasil
      await (syncStorageService ?? SyncStorageService.singleton())
          .saveLastSync(AppConstants.syncKeyAttendance, DateTime.now());

      return Right(
        AttendanceResult(
          items: AttendanceMapper.toEntityList(attendance),
        ),
      );
    } on AppException catch (e) {
      if (e is RequestCancelledException) {
        return const Left(RequestCancelledFailure());
      }
      if (localDataSource != null && _canFallbackToCache(e)) {
        final cached = await localDataSource!.getCachedAttendances(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
        );
        return Right(
          AttendanceResult(
            items: AttendanceMapper.toEntityList(cached),
            isFromCache: true,
          ),
        );
      }
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    } on Exception catch (e) {
      if (localDataSource != null) {
        final cached = await localDataSource!.getCachedAttendances(
          search: params.search,
          startDate: params.startDate,
          endDate: params.endDate,
        );
        return Right(
          AttendanceResult(
            items: AttendanceMapper.toEntityList(cached),
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
