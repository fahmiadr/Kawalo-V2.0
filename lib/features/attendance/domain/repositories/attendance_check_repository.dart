import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';

abstract final class AttendanceCheckErrorCodes {
  static const noSchedule = 'ATTENDANCE_NO_SCHEDULE';
  static const alreadyCompleted = 'ATTENDANCE_ALREADY_COMPLETED';
  static const outOfRadius = 'ATTENDANCE_OUT_OF_RADIUS';
  static const nonceInvalid = 'ATTENDANCE_NONCE_INVALID';
}

/// `FACE_NOT_MATCH` with the server's failure count. The extra fields are
/// optional so an older server still yields a usable failure.
class FaceNotMatchFailure extends Failure {
  const FaceNotMatchFailure(
    super.message, {
    this.failedAttempts,
    this.manualRequestAvailable,
  }) : super(statusCode: 403, errorCode: 'FACE_NOT_MATCH');

  final int? failedAttempts;
  final bool? manualRequestAvailable;

  @override
  List<Object?> get props => [
    ...super.props,
    failedAttempts,
    manualRequestAvailable,
  ];
}

/// A single-use nonce plus the server's face-failure tally, which lets the
/// scan screen offer the manual report before any new attempt is made.
class AttendanceNonce {
  const AttendanceNonce(
    this.value, {
    this.failedAttempts,
    this.manualRequestAvailable,
  });

  final String value;
  final int? failedAttempts;
  final bool? manualRequestAvailable;
}

enum ManualAttendanceReason {
  faceFailed('face_failed'),
  cameraUnavailable('camera_unavailable');

  const ManualAttendanceReason(this.wire);

  final String wire;
}

/// Online only: attendance needs the server for the face check.
abstract interface class AttendanceCheckRepository {
  /// Today's and yesterday's shifts (yesterday for overnight shifts).
  Future<Either<Failure, List<AttendanceSlot>>> getSlots(DateTime today);

  /// A fresh single-use nonce for one `submit`.
  Future<Either<Failure, AttendanceNonce>> issueNonce();

  Future<Either<Failure, AttendanceCheckResult>> submit({
    required Uint8List photo,
    required double latitude,
    required double longitude,
    required String nonce,
  });

  /// `POST /attendance/manual-requests`; returns the request id.
  Future<Either<Failure, String>> requestManual({
    required ManualAttendanceReason reason,
    required double latitude,
    required double longitude,
    String? note,
  });
}
