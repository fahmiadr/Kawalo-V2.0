import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/constants/app_constants.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/repositories/cached_remote_fetch.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/mappers/attendance_mapper.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
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
    required this.syncStorageService,
    this.localDataSource,
    this.networkInfo,
  });

  /// Sumber data absensi jarak jauh.
  final AttendanceRemoteDataSource remoteDataSource;

  /// Sumber data absensi lokal untuk mode offline dan caching.
  final AttendanceLocalDataSource? localDataSource;

  /// Layanan persistensi waktu sinkronisasi.
  final SyncStorageService syncStorageService;

  /// Layanan pengecekan status konektivitas jaringan.
  final NetworkInfo? networkInfo;

  @override
  Future<Either<Failure, AttendanceResult>> getAttendances(
    GetAttendancesParams params,
  ) {
    final local = localDataSource;
    return fetchRemoteWithCacheFallback<AttendanceModel, AttendanceResult>(
      isRefresh: params.isRefresh,
      networkInfo: networkInfo,
      syncStorageService: syncStorageService,
      syncKey: AppConstants.syncKeyAttendance,
      fetchRemote: () => remoteDataSource.getAttendances(
        query: AttendanceQueryModel(
          search: params.search,
          limit: params.limit,
          offset: params.offset,
          startDate: params.startDate,
          endDate: params.endDate,
        ),
        cancelToken: params.cancelToken,
      ),
      toResult: (models, {required isFromCache}) => AttendanceResult(
        items: AttendanceMapper.toEntityList(models),
        isFromCache: isFromCache,
      ),
      cache: local == null
          ? null
          : CacheOps(
              read: () => local.getCachedAttendances(
                search: params.search,
                startDate: params.startDate,
                endDate: params.endDate,
              ),
              write: local.cacheAttendances,
              deleteOlderThan: local.deleteOlderThan,
            ),
    );
  }
}
