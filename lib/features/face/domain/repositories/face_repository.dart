import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/face/domain/entities/face_status.dart';

/// Error codes of the face endpoints the presentation layer branches on.
abstract final class FaceErrorCodes {
  static const serviceUnavailable = 'FACE_SERVICE_UNAVAILABLE';
  static const notRegistered = 'FACE_NOT_REGISTERED';
  static const alreadyRegistered = 'FACE_ALREADY_REGISTERED';
  static const notMatch = 'FACE_NOT_MATCH';
  static const qualityLow = 'FACE_QUALITY_LOW';
  static const duplicate = 'FACE_DUPLICATE';
}

/// Online only: biometric data is never cached on the device.
abstract interface class FaceRepository {
  Future<Either<Failure, FaceStatus>> getStatus();

  /// Sends 1-5 JPEG photos of the user. With [replaceExisting] the stored
  /// face is deleted first (re-registration after a model change).
  Future<Either<Failure, FaceRegistration>> register(
    List<Uint8List> photos, {
    bool replaceExisting = false,
  });

  /// True when something was deleted.
  Future<Either<Failure, bool>> deleteMine();
}
