import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';

/// Feature Composition Root untuk modul Absensi pada Frontend.
///
/// Receives the shared dependencies once and builds a single
/// [AttendanceRepository] that every cubit factory reuses.
final class AttendanceModule {
  AttendanceModule({
    required ApiClient apiClient,
    required Isar isar,
    required NetworkInfo networkInfo,
    SyncStorageService? syncStorageService,
  }) : _syncStorage = syncStorageService ?? SyncStorageService.singleton() {
    repository = AttendanceRepositoryImpl(
      remoteDataSource: AttendanceRemoteDataSourceImpl(apiClient: apiClient),
      localDataSource: AttendanceLocalDataSourceImpl(isar: isar),
      syncStorageService: _syncStorage,
      networkInfo: networkInfo,
    );
  }

  final SyncStorageService _syncStorage;
  late final AttendanceRepository repository;

  /// Merakit dan mengembalikan instance [AttendanceCubit] yang siap pakai.
  AttendanceCubit createCubit() {
    return AttendanceCubit(
      repository: repository,
      syncStorageService: _syncStorage,
    );
  }
}
