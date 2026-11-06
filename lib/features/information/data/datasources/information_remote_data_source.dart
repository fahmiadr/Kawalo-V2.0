import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/information/data/models/create_information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_request_model.dart';
import 'package:kawalo_mobile/features/information/data/models/delete_batch_information_response_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_id_params_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_model.dart';
import 'package:kawalo_mobile/features/information/data/models/information_query_model.dart';
import 'package:kawalo_mobile/features/information/data/models/update_information_model.dart';

/// Kontrak data source jarak jauh untuk fitur informasi / feed.
///
/// Selaras 100% dengan kontrak backend `GetInformationQueryDto`,
/// `CreateInformationDto`, `InformationIdParamsDto`, dan `InformationItemDto`.
abstract class InformationRemoteDataSource {
  /// Mengambil daftar informasi / feed dari REST API backend `/v1/information`.
  ///
  /// Menerima [query] bertipe [InformationQueryModel] sebagai kontrak parameter
  /// query HTTP dan [cancelToken] opsional untuk pembatalan request.
  Future<List<InformationModel>> getInformation({
    required InformationQueryModel query,
    AppCancellationToken? cancelToken,
  });

  /// Membuat data informasi / feed baru via REST API backend
  /// `POST /v1/information`.
  ///
  /// Menerima [data] bertipe [CreateInformationModel] dan [cancelToken]
  /// opsional untuk pembatalan request.
  /// Mengembalikan objek [InformationModel] dari respons server.
  Future<InformationModel> createInformation({
    required CreateInformationModel data,
    AppCancellationToken? cancelToken,
  });

  /// Memperbarui data informasi / feed via REST API backend
  /// `PUT /v1/information/:id`.
  ///
  /// Menerima [params] berisi ID informasi, [data] bertipe
  /// [UpdateInformationModel], dan [cancelToken] opsional untuk pembatalan
  /// request.
  /// Mengembalikan objek [InformationModel] dari respons server.
  Future<InformationModel> updateInformation({
    required InformationIdParamsModel params,
    required UpdateInformationModel data,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus data informasi / feed dari REST API backend
  /// `DELETE /v1/information/:id`.
  ///
  /// Menerima [params] bertipe [InformationIdParamsModel] dan [cancelToken]
  /// opsional untuk pembatalan request.
  Future<void> deleteInformation({
    required InformationIdParamsModel params,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus batch data informasi / feed dari REST API backend
  /// `DELETE /v1/information` dengan body `{ ids: [...] }`.
  ///
  /// Menerima [params] bertipe [DeleteBatchInformationRequestModel] dan
  /// [cancelToken] opsional untuk pembatalan request.
  Future<DeleteBatchInformationResponseModel> deleteBatchInformation({
    required DeleteBatchInformationRequestModel params,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [InformationRemoteDataSource] yang terhubung langsung ke API.
class InformationRemoteDataSourceImpl implements InformationRemoteDataSource {
  /// Membuat instance [InformationRemoteDataSourceImpl].
  const InformationRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP Dio proyek.
  final ApiClient apiClient;

  @override
  Future<List<InformationModel>> getInformation({
    required InformationQueryModel query,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/information',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(InformationModel.fromJson)
          .toList();
    }
    return const [];
  }

  @override
  Future<InformationModel> createInformation({
    required CreateInformationModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.post(
      '/v1/information',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return InformationModel.fromJson(rawData);
  }

  @override
  Future<InformationModel> updateInformation({
    required InformationIdParamsModel params,
    required UpdateInformationModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.put(
      '/v1/information/${params.id}',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return InformationModel.fromJson(rawData);
  }

  @override
  Future<void> deleteInformation({
    required InformationIdParamsModel params,
    AppCancellationToken? cancelToken,
  }) async {
    await apiClient.delete(
      '/v1/information/${params.id}',
      cancelToken: cancelToken?.toDio(),
    );
  }

  @override
  Future<DeleteBatchInformationResponseModel> deleteBatchInformation({
    required DeleteBatchInformationRequestModel params,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.delete(
      '/v1/information',
      body: params.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return DeleteBatchInformationResponseModel.fromJson(rawData);
    }
    return const DeleteBatchInformationResponseModel(deletedCount: 0);
  }
}
