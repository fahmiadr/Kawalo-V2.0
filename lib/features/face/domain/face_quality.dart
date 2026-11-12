import 'package:kawalo_mobile/features/face/domain/face_frame.dart';

/// Why a frame is not good enough for a face photo. The server runs its own
/// gate; this one only spares the user uploads that would be rejected.
enum FaceIssue {
  noFace('Wajah tidak terdeteksi'),
  multipleFaces('Terdeteksi lebih dari satu wajah'),
  tooDark('Kurang cahaya. Cari tempat lebih terang'),
  tooFar('Terlalu jauh. Dekatkan wajah ke kamera'),
  tooClose('Terlalu dekat. Jauhkan sedikit ponsel'),
  offCenter('Wajah belum di tengah. Geser ke dalam oval'),
  tilted('Kepala miring. Luruskan kepala'),
  eyesClosed('Buka mata dan lihat ke kamera');

  const FaceIssue(this.message);

  final String message;
}

/// Thresholds of [faceIssue]. Calibration knobs: tuned on paper, not yet on
/// guards' phones, so adjust here after the device test.
abstract final class FaceQualityLimits {
  static const double minBrightness = 50;
  static const double minFaceWidth = 0.35;
  static const double maxFaceWidth = 0.85;
  static const double maxCenterOffset = 0.15;
  static const double maxYaw = 12;
  static const double maxPitch = 12;
  static const double maxRoll = 10;
  static const double minEyeOpen = 0.4;
}

/// First problem of [frame], or null when it passes.
FaceIssue? faceIssue(FaceFrame frame) {
  if (frame.faces.isEmpty) return FaceIssue.noFace;
  if (frame.faces.length > 1) return FaceIssue.multipleFaces;
  final brightness = frame.brightness;
  if (brightness != null && brightness < FaceQualityLimits.minBrightness) {
    return FaceIssue.tooDark;
  }
  final face = frame.faces.single;
  final size = frame.imageSize;
  if (size.width <= 0 || size.height <= 0) return FaceIssue.noFace;

  final widthRatio = face.box.width / size.width;
  if (widthRatio < FaceQualityLimits.minFaceWidth) return FaceIssue.tooFar;
  if (widthRatio > FaceQualityLimits.maxFaceWidth) return FaceIssue.tooClose;

  final dx = (face.box.center.dx - size.width / 2).abs() / size.width;
  final dy = (face.box.center.dy - size.height / 2).abs() / size.height;
  if (dx > FaceQualityLimits.maxCenterOffset ||
      dy > FaceQualityLimits.maxCenterOffset) {
    return FaceIssue.offCenter;
  }

  if (_beyond(face.yaw, FaceQualityLimits.maxYaw) ||
      _beyond(face.pitch, FaceQualityLimits.maxPitch) ||
      _beyond(face.roll, FaceQualityLimits.maxRoll)) {
    return FaceIssue.tilted;
  }
  if (_below(face.leftEyeOpen, FaceQualityLimits.minEyeOpen) ||
      _below(face.rightEyeOpen, FaceQualityLimits.minEyeOpen)) {
    return FaceIssue.eyesClosed;
  }
  return null;
}

// A missing angle or probability (classification off) does not block.
bool _beyond(double? value, double limit) =>
    value != null && value.abs() > limit;

bool _below(double? value, double limit) => value != null && value < limit;
