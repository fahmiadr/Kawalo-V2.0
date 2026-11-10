import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/schedule/data/models/schedule_model.dart';

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

abstract interface class ScheduleRemoteDataSource {
  Future<List<ScheduleModel>> getMySchedules({
    required DateTime from,
    required DateTime to,
  });
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  const ScheduleRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<ScheduleModel>> getMySchedules({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await apiClient.get(
      '/v1/schedules/me',
      queryParameters: {'from': _isoDate(from), 'to': _isoDate(to)},
    );

    final rawData = response['data'];
    if (rawData is! List) return const [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map(ScheduleModel.fromJson)
        .toList();
  }
}
