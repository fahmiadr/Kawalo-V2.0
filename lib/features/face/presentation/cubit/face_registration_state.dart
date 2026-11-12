import 'package:equatable/equatable.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

sealed class FaceRegistrationState extends Equatable {
  const FaceRegistrationState();

  @override
  List<Object?> get props => [];
}

final class FaceRegistrationConsent extends FaceRegistrationState {
  const FaceRegistrationConsent();
}

final class FaceRegistrationIntro extends FaceRegistrationState {
  const FaceRegistrationIntro();
}

final class FaceRegistrationCapturing extends FaceRegistrationState {
  const FaceRegistrationCapturing({
    required this.captured,
    required this.total,
    this.issue,
  });

  final int captured;
  final int total;

  /// Null while the face passes the gate.
  final FaceIssue? issue;

  @override
  List<Object?> get props => [captured, total, issue];
}

final class FaceRegistrationCameraFault extends FaceRegistrationState {
  const FaceRegistrationCameraFault(this.fault);

  final FaceCameraFault fault;

  @override
  List<Object?> get props => [fault];
}

final class FaceRegistrationUploading extends FaceRegistrationState {
  const FaceRegistrationUploading(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

final class FaceRegistrationSuccess extends FaceRegistrationState {
  const FaceRegistrationSuccess({
    required this.accepted,
    required this.submitted,
  });

  /// Null when the server reported the face as already registered.
  final int? accepted;
  final int submitted;

  @override
  List<Object?> get props => [accepted, submitted];
}

final class FaceRegistrationFailed extends FaceRegistrationState {
  const FaceRegistrationFailed({
    required this.message,
    required this.canResubmit,
  });

  final String message;

  /// True when the same photos can be sent again (network/server trouble);
  /// otherwise retrying takes new photos.
  final bool canResubmit;

  @override
  List<Object?> get props => [message, canResubmit];
}

/// The server has no face model yet (`FACE_SERVICE_UNAVAILABLE`).
final class FaceRegistrationServiceUnavailable extends FaceRegistrationState {
  const FaceRegistrationServiceUnavailable();
}
