import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/core/network/sse_stream_transformer.dart';
import 'package:kawalo_mobile/features/incident/data/models/create_incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_detail_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_query_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/incident_reply_model.dart';
import 'package:kawalo_mobile/features/incident/data/models/post_incident_reply_model.dart';

/// Kontrak sumber data jarak jauh (Remote Data Source) untuk fitur Insiden.
abstract class IncidentRemoteDataSource {
  /// Mengambil daftar laporan insiden dari server backend `GET /v1/incidents`.
  Future<List<IncidentModel>> getIncidents({
    required IncidentQueryModel query,
    AppCancellationToken? cancelToken,
  });

  /// Mengambil detail laporan insiden beserta riwayat balasan awal `GET /v1/incidents/:id`.
  Future<IncidentDetailModel> getIncidentDetail({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });

  /// Membuat laporan insiden baru `POST /v1/incidents`.
  Future<IncidentModel> createIncident({
    required CreateIncidentModel data,
    AppCancellationToken? cancelToken,
  });

  /// Membuka koneksi realtime SSE `GET /v1/incidents/:id/stream`.
  Stream<SseMessage> watchIncidentStream({
    required String incidentId,
    String? lastEventId,
    AppCancellationToken? cancelToken,
  });

  /// Mengirim pesan balasan atau foto baru `POST /v1/incidents/:id/replies`.
  Future<IncidentReplyModel> postIncidentReply({
    required String incidentId,
    required PostIncidentReplyModel data,
    AppCancellationToken? cancelToken,
  });

  /// Menyelesaikan laporan insiden `PATCH /v1/incidents/:id/resolve`.
  Future<IncidentModel> resolveIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus laporan insiden (soft-delete) `DELETE /v1/incidents/:id`.
  Future<void> deleteIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [IncidentRemoteDataSource] menggunakan [ApiClient] dan
/// SSE streaming.
class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  /// Membuat instance [IncidentRemoteDataSourceImpl].
  const IncidentRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP Dio proyek.
  final ApiClient apiClient;

  @override
  Future<List<IncidentModel>> getIncidents({
    required IncidentQueryModel query,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/incidents',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] ?? response;
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(IncidentModel.fromJson)
          .toList();
    }
    return const [];
  }

  @override
  Future<IncidentDetailModel> getIncidentDetail({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/incidents/$incidentId',
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return IncidentDetailModel.fromJson(rawData);
    }
    throw const FormatException('Format data detail insiden tidak valid.');
  }

  @override
  Future<IncidentModel> createIncident({
    required CreateIncidentModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.post(
      '/v1/incidents',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return IncidentModel.fromJson(rawData);
    }
    throw const FormatException('Format respon pembuatan insiden tidak valid.');
  }

  @override
  Stream<SseMessage> watchIncidentStream({
    required String incidentId,
    String? lastEventId,
    AppCancellationToken? cancelToken,
  }) async* {
    final options = Options(
      responseType: ResponseType.stream,
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'text/event-stream',
        if (lastEventId != null && lastEventId.isNotEmpty)
          'Last-Event-ID': lastEventId,
      },
    );

    final response = await apiClient.getStream(
      '/v1/incidents/$incidentId/stream',
      options: options,
      cancelToken: cancelToken?.toDio(),
    );

    final responseBody = response.data;
    if (responseBody != null) {
      yield* responseBody.stream.transform(const SseStreamTransformer());
    }
  }

  @override
  Future<IncidentReplyModel> postIncidentReply({
    required String incidentId,
    required PostIncidentReplyModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.post(
      '/v1/incidents/$incidentId/replies',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return IncidentReplyModel.fromJson(rawData);
    }
    throw const FormatException(
      'Format respon pengiriman balasan tidak valid.',
    );
  }

  @override
  Future<IncidentModel> resolveIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.patch(
      '/v1/incidents/$incidentId/resolve',
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] ?? response;
    if (rawData is Map<String, dynamic>) {
      return IncidentModel.fromJson(rawData);
    }
    throw const FormatException(
      'Format respon penyelesaian insiden tidak valid.',
    );
  }

  @override
  Future<void> deleteIncident({
    required String incidentId,
    AppCancellationToken? cancelToken,
  }) async {
    await apiClient.delete(
      '/v1/incidents/$incidentId',
      cancelToken: cancelToken?.toDio(),
    );
  }
}
