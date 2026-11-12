import 'dart:ui' show Rect, Size;

import 'package:equatable/equatable.dart';

/// One analysed camera frame. Coordinates are in the upright image the user
/// sees (rotation applied), not mirrored.
class FaceFrame extends Equatable {
  const FaceFrame({
    required this.imageSize,
    this.faces = const [],
    this.brightness,
  });

  final Size imageSize;
  final List<DetectedFace> faces;

  /// Mean luma of the frame (0-255), null when the format does not allow it.
  final double? brightness;

  @override
  List<Object?> get props => [imageSize, faces, brightness];
}

class DetectedFace extends Equatable {
  const DetectedFace({
    required this.box,
    this.yaw,
    this.pitch,
    this.roll,
    this.leftEyeOpen,
    this.rightEyeOpen,
  });

  final Rect box;

  /// Head Euler angles in degrees (ML Kit Y, X, Z).
  final double? yaw;
  final double? pitch;
  final double? roll;

  /// Probabilities 0-1.
  final double? leftEyeOpen;
  final double? rightEyeOpen;

  @override
  List<Object?> get props => [box, yaw, pitch, roll, leftEyeOpen, rightEyeOpen];
}
