import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/attendance_admin/data/models/manual_request_model.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

void main() {
  test('maps the API item to an entity', () {
    final entity = const ManualRequestModel({
      'id': '5',
      'status': 'APPROVED',
      'reason': 'camera_unavailable',
      'note': 'Kamera rusak',
      'user_email': 'siti@kawalo.id',
      'user_name': 'Siti',
      'attendance_type': 'CHECK OUT',
      'requested_at': '2026-11-12T08:00:00.000Z',
      'latitude': -6.2,
      'longitude': 106.8,
      'distance_meters': 42,
      'radius_meters': 100,
      'shift_name': 'Shift Pagi',
      'shift_time_window': '07:00 - 15:00',
      'location_name': 'Pos Utama',
      'failed_attempts': 0,
      'decided_by': 'admin@kawalo.id',
      'decided_at': '2026-11-12T08:05:00.000Z',
      'decision_note': 'OK',
    }).toEntity();

    expect(entity.id, '5');
    expect(entity.status, ManualRequestStatus.approved);
    expect(entity.reason, ManualRequestReason.cameraUnavailable);
    expect(entity.latitude, -6.2);
    expect(entity.distanceMeters, 42);
    expect(entity.decidedBy, 'admin@kawalo.id');
    expect(entity.isPending, isFalse);
  });

  test('tolerates missing and unknown values', () {
    final entity = const ManualRequestModel({
      'id': 9,
      'reason': 'something_new',
    }).toEntity();

    expect(entity.id, '9');
    expect(entity.status, ManualRequestStatus.pending);
    expect(entity.reason, ManualRequestReason.unknown);
    expect(entity.latitude, isNull);
    expect(entity.failedAttempts, 0);
  });
}
