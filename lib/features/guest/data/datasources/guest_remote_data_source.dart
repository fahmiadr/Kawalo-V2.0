import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/core/network/cancellation_token.dart';
import 'package:kawalo_mobile/core/network/dio_cancellation_token.dart';
import 'package:kawalo_mobile/features/guest/data/models/checkout_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/create_guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_request_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/delete_batch_guest_response_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_id_params_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/guest_query_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/master_guest_type_model.dart';
import 'package:kawalo_mobile/features/guest/data/models/update_guest_model.dart';

/// Kontrak data source jarak jauh untuk fitur data tamu.
///
/// Selaras 100% dengan kontrak backend `GetGuestsQueryDto`, `GuestItemDto`,
/// `CreateGuestDto`, dan `MasterGuestTypeItemDto`.
abstract class GuestRemoteDataSource {
  /// Mengambil daftar tamu dari server backend `/v1/guests`.
  Future<List<GuestModel>> getGuests({
    required GuestQueryModel query,
    AppCancellationToken? cancelToken,
  });

  /// Mengambil satu tamu dari `GET /v1/guests/:id`. Server menerima id numerik
  /// maupun `qr_uid` pada segmen yang sama; `null` bila grup aktif kosong.
  Future<GuestModel?> getGuest({
    required GuestIdParamsModel params,
    AppCancellationToken? cancelToken,
  });

  /// Mendaftarkan tamu baru ke server backend `POST /v1/guests`.
  Future<GuestModel> createGuest({
    required CreateGuestModel data,
    AppCancellationToken? cancelToken,
  });

  /// Memperbarui data tamu ke server backend `PUT /v1/guests/:id`.
  Future<GuestModel> updateGuest({
    required GuestIdParamsModel params,
    required UpdateGuestModel data,
    AppCancellationToken? cancelToken,
  });

  /// Mengonfirmasi kunjungan tamu ke server backend
  /// `PATCH /v1/guests/:id/acknowledge`. Body-nya sama dengan check-out
  /// (`qr_uid` opsional).
  Future<GuestModel> acknowledgeGuest({
    required GuestIdParamsModel params,
    CheckoutGuestModel? data,
    AppCancellationToken? cancelToken,
  });

  /// Melakukan check-out tamu ke server backend `PATCH /v1/guests/:id/checkout`.
  Future<GuestModel> checkoutGuest({
    required GuestIdParamsModel params,
    CheckoutGuestModel? data,
    AppCancellationToken? cancelToken,
  });

  /// Mengambil daftar master tipe tamu dari server backend `GET /v1/guests/master-types`.
  Future<List<MasterGuestTypeModel>> getMasterGuestTypes({
    AppCancellationToken? cancelToken,
  });

  /// Menghapus data tamu dari server backend `DELETE /v1/guests/:id`.
  Future<void> deleteGuest({
    required GuestIdParamsModel params,
    AppCancellationToken? cancelToken,
  });

  /// Menghapus sekumpulan data tamu dari server backend `DELETE /v1/guests`.
  Future<DeleteBatchGuestResponseModel> deleteBatchGuests({
    required DeleteBatchGuestRequestModel params,
    AppCancellationToken? cancelToken,
  });
}

/// Implementasi [GuestRemoteDataSource] yang memanggil API REST backend.
class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  /// Membuat instance [GuestRemoteDataSourceImpl].
  const GuestRemoteDataSourceImpl({required this.apiClient});

  /// Klien HTTP Dio proyek.
  final ApiClient apiClient;

  @override
  Future<List<GuestModel>> getGuests({
    required GuestQueryModel query,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/guests',
      queryParameters: query.toQueryParams(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(GuestModel.fromJson)
          .toList();
    }
    return const [];
  }

  @override
  Future<GuestModel?> getGuest({
    required GuestIdParamsModel params,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/guests/${Uri.encodeComponent(params.id)}',
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    return rawData is Map<String, dynamic>
        ? GuestModel.fromJson(rawData)
        : null;
  }

  @override
  Future<GuestModel> createGuest({
    required CreateGuestModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.post(
      '/v1/guests',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return GuestModel.fromJson(rawData);
  }

  @override
  Future<GuestModel> updateGuest({
    required GuestIdParamsModel params,
    required UpdateGuestModel data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.put(
      '/v1/guests/${params.id}',
      body: data.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return GuestModel.fromJson(rawData);
  }

  @override
  Future<GuestModel> acknowledgeGuest({
    required GuestIdParamsModel params,
    CheckoutGuestModel? data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.patch(
      '/v1/guests/${params.id}/acknowledge',
      body: data?.toJson() ?? const {},
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return GuestModel.fromJson(rawData);
  }

  @override
  Future<GuestModel> checkoutGuest({
    required GuestIdParamsModel params,
    CheckoutGuestModel? data,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.patch(
      '/v1/guests/${params.id}/checkout',
      body: data?.toJson() ?? const {},
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'] as Map<String, dynamic>;
    return GuestModel.fromJson(rawData);
  }

  @override
  Future<List<MasterGuestTypeModel>> getMasterGuestTypes({
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      '/v1/guests/master-types',
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(MasterGuestTypeModel.fromJson)
          .toList();
    }
    return const [];
  }

  @override
  Future<void> deleteGuest({
    required GuestIdParamsModel params,
    AppCancellationToken? cancelToken,
  }) async {
    await apiClient.delete(
      '/v1/guests/${params.id}',
      cancelToken: cancelToken?.toDio(),
    );
  }

  @override
  Future<DeleteBatchGuestResponseModel> deleteBatchGuests({
    required DeleteBatchGuestRequestModel params,
    AppCancellationToken? cancelToken,
  }) async {
    final response = await apiClient.delete(
      '/v1/guests',
      body: params.toJson(),
      cancelToken: cancelToken?.toDio(),
    );

    final rawData = response['data'];
    if (rawData is Map<String, dynamic>) {
      return DeleteBatchGuestResponseModel.fromJson(rawData);
    }
    return const DeleteBatchGuestResponseModel(deletedCount: 0);
  }
}
