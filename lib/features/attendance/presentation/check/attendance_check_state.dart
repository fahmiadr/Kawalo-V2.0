import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_check_repository.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

sealed class AttendanceCheckState extends Equatable {
  const AttendanceCheckState();

  @override
  List<Object?> get props => [];
}

final class AttendanceCheckLoading extends AttendanceCheckState {
  const AttendanceCheckLoading();
}

/// Attendance needs the server (face check), so it is blocked offline.
final class AttendanceCheckOffline extends AttendanceCheckState {
  const AttendanceCheckOffline();
}

final class AttendanceCheckLoadFailed extends AttendanceCheckState {
  const AttendanceCheckLoadFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// `FACE_SERVICE_UNAVAILABLE`: no face model on the server yet.
final class AttendanceCheckServiceUnavailable extends AttendanceCheckState {
  const AttendanceCheckServiceUnavailable();
}

final class AttendanceCheckFaceNotRegistered extends AttendanceCheckState {
  const AttendanceCheckFaceNotRegistered({required this.reregister});

  /// The stored face must be deleted before registering again.
  final bool reregister;

  @override
  List<Object?> get props => [reregister];
}

final class AttendanceCheckNoSchedule extends AttendanceCheckState {
  const AttendanceCheckNoSchedule(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// Checked in and out already. [slot] is null when only the server knew.
final class AttendanceCheckCompleted extends AttendanceCheckState {
  const AttendanceCheckCompleted(this.slot);

  final AttendanceSlot? slot;

  @override
  List<Object?> get props => [slot];
}

final class AttendanceCheckLocationFailed extends AttendanceCheckState {
  const AttendanceCheckLocationFailed(this.result);

  final LocationResult result;

  @override
  List<Object?> get props => [result];
}

final class AttendanceCheckReady extends AttendanceCheckState {
  const AttendanceCheckReady({
    required this.slot,
    required this.action,
    this.accuracyMeters,
  });

  final AttendanceSlot slot;
  final AttendanceAction action;
  final double? accuracyMeters;

  @override
  List<Object?> get props => [slot, action, accuracyMeters];
}

final class AttendanceCheckScanning extends AttendanceCheckState {
  const AttendanceCheckScanning({
    required this.slot,
    required this.action,
    this.issue,
    this.canRequestManual = false,
  });

  final AttendanceSlot slot;
  final AttendanceAction action;

  /// Null while the face passes the quality gate.
  final FaceIssue? issue;

  /// Offers "Lapor ke Admin" next to the camera; scanning is never blocked.
  final bool canRequestManual;

  @override
  List<Object?> get props => [slot, action, issue, canRequestManual];
}

final class AttendanceCheckVerifying extends AttendanceCheckState {
  const AttendanceCheckVerifying({required this.slot, required this.action});

  final AttendanceSlot slot;
  final AttendanceAction action;

  @override
  List<Object?> get props => [slot, action];
}

final class AttendanceCheckSuccess extends AttendanceCheckState {
  const AttendanceCheckSuccess(this.result);

  final AttendanceCheckResult result;

  @override
  List<Object?> get props => [result];
}

final class AttendanceCheckFaceNotMatch extends AttendanceCheckState {
  const AttendanceCheckFaceNotMatch({
    required this.message,
    required this.failedAttempts,
    required this.canRequestManual,
  });

  final String message;
  final int failedAttempts;

  /// The manual report is an extra choice; "Coba Lagi" is always offered.
  final bool canRequestManual;

  @override
  List<Object?> get props => [message, failedAttempts, canRequestManual];
}

final class AttendanceCheckOutOfRadius extends AttendanceCheckState {
  const AttendanceCheckOutOfRadius(this.message);

  /// The server's message, which carries the distance and the radius.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Refused by the server for a reason a new scan may fix.
final class AttendanceCheckRejected extends AttendanceCheckState {
  const AttendanceCheckRejected({required this.title, required this.message});

  final String title;
  final String message;

  @override
  List<Object?> get props => [title, message];
}

/// Network or server trouble while sending; the same photo can be resent.
final class AttendanceCheckSubmitFailed extends AttendanceCheckState {
  const AttendanceCheckSubmitFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AttendanceCheckCameraFault extends AttendanceCheckState {
  const AttendanceCheckCameraFault(this.fault);

  final FaceCameraFault fault;

  @override
  List<Object?> get props => [fault];
}

final class AttendanceCheckManualRequest extends AttendanceCheckState {
  const AttendanceCheckManualRequest(
    this.reason, {
    this.sending = false,
    this.error,
  });

  final ManualAttendanceReason reason;
  final bool sending;
  final String? error;

  @override
  List<Object?> get props => [reason, sending, error];
}

final class AttendanceCheckManualSent extends AttendanceCheckState {
  const AttendanceCheckManualSent({required this.alreadyPending});

  /// A pending request already existed (409); nothing new was created.
  final bool alreadyPending;

  @override
  List<Object?> get props => [alreadyPending];
}
