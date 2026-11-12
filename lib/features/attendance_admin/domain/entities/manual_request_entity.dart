import 'package:equatable/equatable.dart';

enum ManualRequestStatus {
  pending('PENDING', 'Menunggu'),
  approved('APPROVED', 'Disetujui'),
  rejected('REJECTED', 'Ditolak');

  const ManualRequestStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ManualRequestStatus fromApi(String? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => pending);
}

enum ManualRequestReason {
  faceFailed,
  cameraUnavailable,
  unknown;

  static ManualRequestReason fromApi(String? value) => switch (value) {
    'face_failed' => faceFailed,
    'camera_unavailable' => cameraUnavailable,
    _ => unknown,
  };
}

/// A guard's request for an admin to record a check-in/out by hand when the
/// face check failed or the camera was unavailable.
class ManualRequestEntity extends Equatable {
  const ManualRequestEntity({
    required this.id,
    required this.status,
    required this.reason,
    required this.userEmail,
    required this.userName,
    required this.attendanceType,
    this.avatarUrl,
    this.note,
    this.requestedAt,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.radiusMeters,
    this.shiftName,
    this.shiftTimeWindow,
    this.locationName,
    this.failedAttempts = 0,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
  });

  final String id;
  final ManualRequestStatus status;
  final ManualRequestReason reason;
  final String userEmail;
  final String userName;
  final String? avatarUrl;

  /// Server wording, for example `CHECK IN` / `CHECK OUT`.
  final String attendanceType;
  final String? note;
  final String? requestedAt;
  final double? latitude;
  final double? longitude;
  final int? distanceMeters;
  final int? radiusMeters;
  final String? shiftName;
  final String? shiftTimeWindow;
  final String? locationName;
  final int failedAttempts;
  final String? decidedBy;
  final String? decidedAt;
  final String? decisionNote;

  bool get isPending => status == ManualRequestStatus.pending;

  @override
  List<Object?> get props => [
    id,
    status,
    reason,
    userEmail,
    userName,
    avatarUrl,
    attendanceType,
    note,
    requestedAt,
    latitude,
    longitude,
    distanceMeters,
    radiusMeters,
    shiftName,
    shiftTimeWindow,
    locationName,
    failedAttempts,
    decidedBy,
    decidedAt,
    decisionNote,
  ];
}
