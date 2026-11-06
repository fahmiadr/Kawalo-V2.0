import 'package:isar_community/isar.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/domain/usecases/get_attendances/get_attendances_usecase.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';

/// Feature Composition Root untuk modul Absensi pada Frontend.
///
/// Bertanggung jawab atas inisialisasi dan perakitan Dependency Injection
/// (DataSources -> Repository -> UseCases -> Cubit) di tingkat fitur,
/// selaras dengan pola modular Clean Architecture pada backend.
abstract final class AttendanceModule {
  /// Merakit dan mengembalikan instance [AttendanceCubit] yang siap pakai.
  static AttendanceCubit createCubit({
    required ApiClient apiClient,
    required Isar isar,
    SyncStorageService? syncStorageService,
    NetworkInfo? networkInfo,
  }) {
    final syncStorage =
        syncStorageService ?? SyncStorageService.singleton();
    final effectiveNetworkInfo = networkInfo ?? NetworkInfoImpl();
    final remoteDataSource =
        AttendanceRemoteDataSourceImpl(apiClient: apiClient);

    final attendanceLocalDataSource = AttendanceLocalDataSourceImpl(
      isar: isar,
    );

    final repository = AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: attendanceLocalDataSource,
      syncStorageService: syncStorage,
      networkInfo: effectiveNetworkInfo,
    );

    final useCase = GetAttendancesUseCase(repository);

    return AttendanceCubit(
      getAttendancesUseCase: useCase,
      syncStorageService: syncStorage,
    );
  }
}
