import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

/// Response item of `GET /attendance/manual-requests`. Hand-written because
/// the server owns the shape and most fields are optional.
class ManualRequestModel {
  const ManualRequestModel(this.json);

  final Map<String, dynamic> json;

  String? _string(String key) => json[key]?.toString();

  double? _double(String key) => (json[key] as num?)?.toDouble();
  int? _int(String key) => (json[key] as num?)?.toInt();

  ManualRequestEntity toEntity() => ManualRequestEntity(
    id: _string('id') ?? '',
    status: ManualRequestStatus.fromApi(_string('status')),
    reason: ManualRequestReason.fromApi(_string('reason')),
    userEmail: _string('user_email') ?? '',
    userName: _string('user_name') ?? '',
    avatarUrl: _string('avatar_url'),
    attendanceType: _string('attendance_type') ?? '',
    note: _string('note'),
    requestedAt: _string('requested_at'),
    latitude: _double('latitude'),
    longitude: _double('longitude'),
    distanceMeters: _int('distance_meters'),
    radiusMeters: _int('radius_meters'),
    shiftName: _string('shift_name'),
    shiftTimeWindow: _string('shift_time_window'),
    locationName: _string('location_name'),
    failedAttempts: _int('failed_attempts') ?? 0,
    decidedBy: _string('decided_by'),
    decidedAt: _string('decided_at'),
    decisionNote: _string('decision_note'),
  );
}
