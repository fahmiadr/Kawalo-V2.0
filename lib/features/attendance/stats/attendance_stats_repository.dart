import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/network_error_handler.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';

abstract class AttendanceStatsRepository {
  /// [from] and [to] are inclusive `YYYY-MM-DD` dates (server caps the span
  /// at 92 days).
  Future<Either<Failure, AttendanceStats>> getStats({
    required String from,
    required String to,
  });
}

class AttendanceStatsRepositoryImpl implements AttendanceStatsRepository {
  const AttendanceStatsRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Either<Failure, AttendanceStats>> getStats({
    required String from,
    required String to,
  }) async {
    try {
      final response = await apiClient.get(
        '/v1/attendance/stats',
        queryParameters: {'from': from, 'to': to},
      );
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Ringkasan absensi tidak valid.'));
      }
      return Right(AttendanceStats.fromJson(data));
    } on Object catch (e) {
      return Left(NetworkErrorHandler.handleExceptionToFailure(e));
    }
  }
}
