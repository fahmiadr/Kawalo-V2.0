import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_model.dart';
import 'package:kawalo_mobile/features/shift/data/models/shift_request_model.dart';

abstract interface class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShifts();

  Future<ShiftModel> createShift(ShiftRequestModel request);

  Future<ShiftModel> updateShift(String uid, ShiftRequestModel request);

  Future<void> deleteShift(String uid);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  const ShiftRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ShiftModel>> getShifts() async {
    final response = await apiClient.get('/v1/shifts');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ShiftModel.fromJson)
        .toList();
  }

  @override
  Future<ShiftModel> createShift(ShiftRequestModel request) async =>
      _single(await apiClient.post('/v1/shifts', body: request.toJson()));

  @override
  Future<ShiftModel> updateShift(String uid, ShiftRequestModel request) async =>
      _single(
        await apiClient.put(
          '/v1/shifts/${Uri.encodeComponent(uid)}',
          body: request.toJson(),
        ),
      );

  @override
  Future<void> deleteShift(String uid) async {
    await apiClient.delete('/v1/shifts/${Uri.encodeComponent(uid)}');
  }

  ShiftModel _single(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Respons shift dari server tidak valid.');
    }
    return ShiftModel.fromJson(data);
  }
}
