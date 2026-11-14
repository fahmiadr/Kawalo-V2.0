import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_model.dart';
import 'package:kawalo_mobile/features/operational/data/models/operational_query_model.dart';

/// Kontrak remote datasource untuk aktivitas operasional tenaga kerja.
///
/// Selaras 100% dengan kontrak backend `GetOperationalQueryDto` dan
/// `OperationalWorkerItemDto`.
abstract class OperationalRemoteDataSource {
  /// Mengambil daftar personil operasional dari server backend `/v1/operational`.
  ///
  /// Menerima [query] bertipe [OperationalQueryModel] sebagai kontrak parameter
  /// query HTTP dan [cancelToken] opsional untuk pembatalan request.
  Future<List<OperationalModel>> getOperationals({
    required OperationalQueryModel query,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [OperationalRemoteDataSource] yang memanggil API REST backend.
class OperationalRemoteDataSourceImpl implements OperationalRemoteDataSource {
  /// Membuat instance [OperationalRemoteDataSourceImpl].
  const OperationalRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP Dio proyek.
  final ApiClient apiClient;

  @override
  Future<List<OperationalModel>> getOperationals({
    required OperationalQueryModel query,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/operational',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(OperationalModel.fromJson)
          .toList();
    }
    return const [];
  }
}
