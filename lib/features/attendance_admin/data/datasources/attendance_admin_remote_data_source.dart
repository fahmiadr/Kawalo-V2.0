import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/attendance_setting_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/manual_request_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/face_photo_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

class AttendanceAdminRemoteDataSource {
  const AttendanceAdminRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ManualRequestModel>> getManualRequests({
    required ManualRequestStatus status,
    required int limit,
    required int offset,
  }) async {
    final response = await apiClient.get(
      '/v1/attendance/manual-requests',
      queryParameters: {
        'status': status.apiValue,
        'limit': limit,
        'offset': offset,
      },
    );
    return _items(response).map(ManualRequestModel.new).toList();
  }

  Future<void> decide({
    required String id,
    required bool approve,
    String? note,
  }) async {
    await apiClient.patch(
      '/v1/attendance/manual-requests/$id',
      body: {
        'action': approve ? 'approve' : 'reject',
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<List<FacePhotoEntity>> getFacePhotos(String email) async {
    final response = await apiClient.get(
      '/v1/faces/${Uri.encodeComponent(email)}/photos',
    );
    return _items(response)
        .map(
          (json) => FacePhotoEntity(
            id: json['id'].toString(),
            createdAt: json['created_at']?.toString(),
          ),
        )
        .toList();
  }

  Future<AttendanceSettingModel> getSetting() async =>
      _setting(await apiClient.get('/v1/attendance/settings'));

  /// A null [percent] restores the server default.
  Future<AttendanceSettingModel> saveSetting(int? percent) async => _setting(
    await apiClient.put(
      '/v1/attendance/settings',
      body: {'face_match_percent': percent},
    ),
  );

  static AttendanceSettingModel _setting(Map<String, dynamic> response) {
    final data = response['data'];
    return AttendanceSettingModel(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final data = response['data'];
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }
}
