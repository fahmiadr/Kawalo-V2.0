import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/attendance_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';

/// Kontrak repositori domain untuk modul data absensi dengan dukungan
/// transparansi sumber data (cache offline vs server remote).
abstract class AttendanceRepository {
  /// Mengambil daftar data absensi dengan filter pencarian, rentang tanggal,
  /// pagination, dan transparansi sumber data.
  Future<Either<Failure, AttendanceResult>> getAttendances(
    GetAttendancesParams params,
  );
}
