import 'package:equatable/equatable.dart';

/// `GET /faces/status` of the signed-in user.
class FaceStatus extends Equatable {
  const FaceStatus({
    required this.available,
    required this.registered,
    this.registeredAt,
    this.photoCount = 0,
    this.needsReregistration = false,
  });

  /// False while the server has no face model: nothing can be registered or
  /// verified, so the app must not start a camera flow.
  final bool available;
  final bool registered;
  final DateTime? registeredAt;
  final int photoCount;

  /// Registered with an older model: verification refuses until the user
  /// deletes the data and registers again.
  final bool needsReregistration;

  bool get usable => registered && !needsReregistration;

  @override
  List<Object?> get props => [
    available,
    registered,
    registeredAt,
    photoCount,
    needsReregistration,
  ];
}

/// `POST /faces/register` result.
class FaceRegistration extends Equatable {
  const FaceRegistration({required this.photoCount, this.rejectedCount = 0});

  /// Photos the server accepted; [rejectedCount] failed its quality gate.
  final int photoCount;
  final int rejectedCount;

  @override
  List<Object?> get props => [photoCount, rejectedCount];
}
