import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_model.dart';
import 'package:kawalo_mobile/features/attendance/data/models/attendance_query_model.dart';

/// Kontrak data source jarak jauh untuk fitur data absensi.
///
/// Selaras 100% dengan kontrak backend `GetAttendanceQueryDto` dan
/// `AttendanceItemDto`.
abstract class AttendanceRemoteDataSource {
  /// Mengambil daftar absensi dari endpoint REST API backend `/v1/attendance`.
  ///
  /// Menerima [query] bertipe [AttendanceQueryModel] sebagai kontrak parameter
  /// query HTTP dan [cancelToken] opsional untuk pembatalan request.
  Future<List<AttendanceModel>> getAttendances({
    required AttendanceQueryModel query,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [AttendanceRemoteDataSource] yang berkomunikasi langsung
/// dengan endpoint REST API backend menggunakan [ApiClient].
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  /// Membuat instance [AttendanceRemoteDataSourceImpl].
  const AttendanceRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP Dio aplikasi.
  final ApiClient apiClient;

  @override
  Future<List<AttendanceModel>> getAttendances({
    required AttendanceQueryModel query,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/attendance',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(AttendanceModel.fromJson)
          .toList();
    }
    return const [];
  }
}
