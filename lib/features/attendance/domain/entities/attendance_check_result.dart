import 'package:equatable/equatable.dart';

/// `status` of `POST /attendance`. Tolerance is applied by the server.
enum AttendanceCheckStatus { onTime, late, earlyLeave }

/// A recorded check-in or check-out.
class AttendanceCheckResult extends Equatable {
  const AttendanceCheckResult({
    required this.id,
    required this.isCheckIn,
    required this.attendanceAt,
    required this.status,
    this.lateMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.shiftName,
    this.shiftTimeWindow,
    this.locationName,
    this.distanceMeters,
  });

  final String id;
  final bool isCheckIn;

  /// Local time.
  final DateTime attendanceAt;
  final AttendanceCheckStatus status;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final String? shiftName;
  final String? shiftTimeWindow;
  final String? locationName;

  /// Null when the shift has no geofence.
  final int? distanceMeters;

  /// User decision (12 Nov 2026): a late check-in and an early check-out are
  /// shown red, everything else green.
  bool get isWarning => status != AttendanceCheckStatus.onTime;

  @override
  List<Object?> get props => [
    id,
    isCheckIn,
    attendanceAt,
    status,
    lateMinutes,
    earlyLeaveMinutes,
    shiftName,
    shiftTimeWindow,
    locationName,
    distanceMeters,
  ];
}
