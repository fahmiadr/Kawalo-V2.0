import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/attendance_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';

/// Use case untuk mengambil daftar data absensi dari repositori.
class GetAttendancesUseCase
    implements UseCase<AttendanceResult, GetAttendancesParams> {
  /// Membuat instance [GetAttendancesUseCase].
  const GetAttendancesUseCase(this.repository);

  /// Repositori data absensi.
  final AttendanceRepository repository;

  @override
  Future<Either<Failure, AttendanceResult>> call(GetAttendancesParams params) {
    return repository.getAttendances(params);
  }
}
