import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';

ManualRequestEntity manualRequest({
  String id = '5',
  ManualRequestStatus status = ManualRequestStatus.pending,
}) => ManualRequestEntity(
  id: id,
  status: status,
  reason: ManualRequestReason.faceFailed,
  userEmail: 'siti@kawalo.id',
  userName: 'Siti Rahmawati',
  attendanceType: 'CHECK IN',
  note: 'Wajah ditolak tiga kali',
  requestedAt: '2026-11-12T00:14:00.000Z',
  latitude: -6.2,
  longitude: 106.8,
  distanceMeters: 42,
  radiusMeters: 100,
  shiftName: 'Shift Pagi',
  shiftTimeWindow: '07:00 - 15:00',
  failedAttempts: 3,
);

AuthSessionEntity session(String role) => AuthSessionEntity(
  userId: '1',
  email: 'admin@kawalo.id',
  name: 'Admin',
  role: role,
  allowAdmin: false,
  allowPatrol: false,
  allowMonPatrol: false,
);

AttendanceSettingEntity attendanceSetting({
  int percent = 40,
  bool isDefault = true,
  String? updatedBy,
  String? updatedAt,
}) => AttendanceSettingEntity(
  faceMatchPercent: percent,
  defaultPercent: 40,
  minPercent: 20,
  maxPercent: 95,
  isDefault: isDefault,
  updatedBy: updatedBy,
  updatedAt: updatedAt,
);
