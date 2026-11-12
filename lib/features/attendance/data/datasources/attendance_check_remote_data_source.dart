import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:kawalo_mobile/core/network/api_client.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/face/data/datasources/face_multipart.dart';

/// Check-in/out endpoints. JSON is parsed by hand on purpose (small payloads,
/// no generated code for this flow).
class AttendanceCheckRemoteDataSource {
  const AttendanceCheckRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AttendanceSlot>> getSlots(DateTime today) async {
    final body = await apiClient.get(
      '/v1/schedules/me',
      queryParameters: {
        'from': _ymd(DateTime(today.year, today.month, today.day - 1)),
        'to': _ymd(today),
      },
    );
    final data = body['data'];
    if (data is! List) return const [];
    return [
      for (final raw in data.whereType<Map<String, dynamic>>())
        if (_parseDate(raw['date']) case final date?)
          AttendanceSlot(
            date: date,
            shiftName: raw['shift_name']?.toString() ?? 'Shift',
            startTime: raw['start_time']?.toString() ?? '00:00',
            endTime: raw['end_time']?.toString() ?? '00:00',
            locationName: _text(raw['location_name']),
            checkin: _text(raw['checkin']),
            checkout: _text(raw['checkout']),
          ),
    ];
  }

  Future<AttendanceNonce> issueNonce() async {
    final body = await apiClient.post('/v1/attendance/nonce');
    return parseNonce(_map(body['data']));
  }

  static AttendanceNonce parseNonce(Map<String, dynamic> data) {
    final nonce = data['nonce']?.toString();
    if (nonce == null || nonce.isEmpty) {
      throw const FormatException('nonce missing');
    }
    final attempts = data['failed_attempts'];
    final available = data['manual_request_available'];
    return AttendanceNonce(
      nonce,
      failedAttempts: attempts is num ? attempts.toInt() : null,
      manualRequestAvailable: available is bool ? available : null,
    );
  }

  Future<AttendanceCheckResult> submit({
    required Uint8List photo,
    required double latitude,
    required double longitude,
    required String nonce,
  }) async {
    final body = await postFaceMultipart(
      apiClient,
      '/v1/attendance',
      () => FormData.fromMap({
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'nonce': nonce,
        'photo': MultipartFile.fromBytes(
          photo,
          filename: 'attendance.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      }),
    );
    return parseCheckResult(_map(body['data']));
  }

  Future<String> requestManual({
    required ManualAttendanceReason reason,
    required double latitude,
    required double longitude,
    String? note,
  }) async {
    final body = await apiClient.post(
      '/v1/attendance/manual-requests',
      body: {
        'reason': reason.wire,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return _map(body['data'])['id']?.toString() ?? '';
  }

  static AttendanceCheckResult parseCheckResult(Map<String, dynamic> data) {
    final type = '${data['attendance_type']} ${data['category']}'.toLowerCase();
    return AttendanceCheckResult(
      id: data['id']?.toString() ?? '',
      isCheckIn: type.contains('check in') || type.contains('masuk'),
      attendanceAt:
          DateTime.tryParse(
            data['attendance_dt']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      status: switch (data['status']) {
        'late' => AttendanceCheckStatus.late,
        'early_leave' => AttendanceCheckStatus.earlyLeave,
        _ => AttendanceCheckStatus.onTime,
      },
      lateMinutes: (data['late_minutes'] as num?)?.toInt() ?? 0,
      earlyLeaveMinutes: (data['early_leave_minutes'] as num?)?.toInt() ?? 0,
      shiftName: _text(data['shift_name']),
      shiftTimeWindow: _text(data['shift_time_window']),
      locationName: _text(data['location_name']),
      distanceMeters: (data['distance_meters'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

  /// Legacy rows store "unset" as '', 'N/A' or 'null' (same rule as the API).
  static String? _text(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == 'N/A' || value == 'null') {
      return null;
    }
    return value;
  }

  static DateTime? _parseDate(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
