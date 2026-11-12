import 'package:kawalo_mobile/core/error/exceptions.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_option_models.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_preview_model.dart';
import 'package:kawalo_mobile/features/forecast/data/models/forecast_request_model.dart';

abstract interface class ForecastRemoteDataSource {
  Future<List<ForecastShiftModel>> getShifts();

  Future<List<ForecastMemberModel>> getMembers();

  Future<ForecastPreviewModel> preview(ForecastRequestModel request);

  Future<ForecastResultModel> commit(ForecastRequestModel request);
}

class ForecastRemoteDataSourceImpl implements ForecastRemoteDataSource {
  const ForecastRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ForecastShiftModel>> getShifts() async {
    final response = await apiClient.get('/v1/shifts');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ForecastShiftModel.fromJson)
        .toList();
  }

  @override
  Future<List<ForecastMemberModel>> getMembers() async {
    final response = await apiClient.get('/v1/groups/members');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ForecastMemberModel.fromJson)
        .toList();
  }

  @override
  Future<ForecastPreviewModel> preview(ForecastRequestModel request) async {
    final response = await apiClient.post(
      '/v1/schedules/generate/preview',
      body: request.toJson(),
    );
    return ForecastPreviewModel.fromJson(_data(response));
  }

  @override
  Future<ForecastResultModel> commit(ForecastRequestModel request) async {
    final response = await apiClient.post(
      '/v1/schedules/generate',
      body: request.toJson(),
    );
    return ForecastResultModel.fromJson(_data(response));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const ServerException('Respons dari server tidak dapat dibaca.');
  }
}
