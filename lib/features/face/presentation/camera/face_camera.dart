import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';

enum FaceCameraFault {
  /// Camera permission refused; the UI offers the app settings.
  permissionDenied,

  /// No front camera, or it failed to open.
  unavailable,
}

class FaceCameraException implements Exception {
  const FaceCameraException(this.fault);

  final FaceCameraFault fault;

  @override
  String toString() => 'FaceCameraException($fault)';
}

/// Seam between the face flows and the camera + ML Kit plugins, so cubits are
/// tested without a camera. One instance owns one front-camera session.
abstract interface class FaceCamera {
  /// Opens the front camera and starts face detection. Throws
  /// [FaceCameraException].
  Future<void> start();

  /// One event per analysed preview frame.
  Stream<FaceFrame> get frames;

  /// A still JPEG from `takePicture()` (EXIF orientation intact; the server
  /// applies it). Detection pauses while the photo is taken.
  Future<Uint8List> capture();

  /// Mirrored front-camera preview; empty until [start] completes.
  Widget buildPreview(BuildContext context);

  Future<void> dispose();
}
