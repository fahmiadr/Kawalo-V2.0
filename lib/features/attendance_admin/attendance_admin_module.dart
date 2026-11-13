import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/datasources/attendance_admin_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/repositories/attendance_admin_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_location_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_setting_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/face_photos_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';

/// Composition root of the admin attendance tools (manual request approval,
/// face registration photos, the face match threshold and the attendance
/// point). Nothing is cached
/// offline, so it is not a `CacheWipeableModule`.
final class AttendanceAdminModule {
  AttendanceAdminModule({required ApiClient apiClient})
    : repository = AttendanceAdminRepositoryImpl(
        remoteDataSource: AttendanceAdminRemoteDataSource(apiClient: apiClient),
        photoFetcher: AuthenticatedPhotoFetcher(apiClient: apiClient),
      );

  final AttendanceAdminRepository repository;

  ManualRequestsCubit createManualRequestsCubit() =>
      ManualRequestsCubit(repository: repository);

  AttendanceSettingCubit createSettingCubit() =>
      AttendanceSettingCubit(repository: repository);

  AttendanceLocationCubit createLocationCubit() =>
      AttendanceLocationCubit(repository: repository);

  FacePhotosCubit createFacePhotosCubit(String email) =>
      FacePhotosCubit(repository: repository, email: email);
}
