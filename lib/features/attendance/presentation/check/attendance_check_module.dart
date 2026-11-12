import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_info.dart';
import 'package:kawalo_mobile/features/attendance/data/datasources/attendance_check_remote_data_source.dart';
import 'package:kawalo_mobile/features/attendance/data/repositories/attendance_check_repository_impl.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';

/// Composition root of check-in/out. Online only, nothing cached, so it is
/// not a `CacheWipeableModule`.
final class AttendanceCheckModule {
  AttendanceCheckModule({
    required ApiClient apiClient,
    required this.networkInfo,
  }) : repository = AttendanceCheckRepositoryImpl(
         remoteDataSource: AttendanceCheckRemoteDataSource(
           apiClient: apiClient,
         ),
       );

  final AttendanceCheckRepository repository;
  final NetworkInfo networkInfo;
}
