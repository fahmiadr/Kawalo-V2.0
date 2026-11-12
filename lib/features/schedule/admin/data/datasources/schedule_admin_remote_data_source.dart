import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/schedule/admin/data/models/schedule_admin_models.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';

abstract interface class ScheduleAdminRemoteDataSource {
  Future<List<ManagedScheduleModel>> getSchedules({
    required DateTime from,
    required DateTime to,
    String? email,
  });

  Future<List<ShiftOptionModel>> getShifts();

  Future<void> create(ScheduleEntry entry, {required bool overwrite});

  Future<BulkScheduleResultModel> createBulk(
    List<ScheduleEntry> entries, {
    required bool overwrite,
  });

  Future<void> update(String id, ScheduleEntry entry);

  Future<DeleteSchedulesResultModel> deleteMany(List<String> ids);
}

class ScheduleAdminRemoteDataSourceImpl
    implements ScheduleAdminRemoteDataSource {
  const ScheduleAdminRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  List<Map<String, dynamic>> _list(Map<String, dynamic> response) {
    final data = response['data'];
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }

  @override
  Future<List<ManagedScheduleModel>> getSchedules({
    required DateTime from,
    required DateTime to,
    String? email,
  }) async {
    final response = await apiClient.get(
      '/v1/schedules',
      queryParameters: {
        'from': isoDate(from),
        'to': isoDate(to),
        'email': ?email,
      },
    );
    return _list(response).map(ManagedScheduleModel.fromJson).toList();
  }

  @override
  Future<List<ShiftOptionModel>> getShifts() async {
    final response = await apiClient.get('/v1/shifts');
    return _list(response).map(ShiftOptionModel.fromJson).toList();
  }

  @override
  Future<void> create(ScheduleEntry entry, {required bool overwrite}) async {
    await apiClient.post(
      '/v1/schedules',
      body: {...scheduleEntryToJson(entry), 'overwrite': overwrite},
    );
  }

  @override
  Future<BulkScheduleResultModel> createBulk(
    List<ScheduleEntry> entries, {
    required bool overwrite,
  }) async {
    final response = await apiClient.post(
      '/v1/schedules/bulk',
      body: {
        'items': entries.map(scheduleEntryToJson).toList(),
        'overwrite': overwrite,
      },
    );
    final data = response['data'];
    return BulkScheduleResultModel.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  @override
  Future<void> update(String id, ScheduleEntry entry) async {
    await apiClient.put('/v1/schedules/$id', body: scheduleEntryToJson(entry));
  }

  @override
  Future<DeleteSchedulesResultModel> deleteMany(List<String> ids) async {
    final response = await apiClient.delete(
      '/v1/schedules',
      body: {'ids': ids},
    );
    final data = response['data'];
    return DeleteSchedulesResultModel.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }
}
