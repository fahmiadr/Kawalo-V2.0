import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

/// [FaceCamera] on the `camera` plugin with ML Kit face detection on the
/// preview stream. Photos are taken with `takePicture()`, never assembled
/// from stream frames.
class MlKitFaceCamera implements FaceCamera {
  MlKitFaceCamera() {
    // `hide`/`show` rather than `inactive`: a permission dialog makes the app
    // inactive while `initialize()` is still waiting for it.
    _lifecycle = AppLifecycleListener(onHide: _pause, onShow: _resume);
  }

  late final AppLifecycleListener _lifecycle;
  final ValueNotifier<CameraController?> _controller = ValueNotifier(null);
  final StreamController<FaceFrame> _frames = StreamController.broadcast();
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(enableClassification: true, minFaceSize: 0.15),
  );
  CameraDescription? _description;
  bool _busy = false;
  bool _disposed = false;

  static const Map<DeviceOrientation, int> _deviceRotation = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  Stream<FaceFrame> get frames => _frames.stream;

  @override
  Future<void> start() async {
    if (_controller.value != null) return;
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      throw FaceCameraException(_fault(e));
    }
    final front = cameras
        .where((c) => c.lensDirection == CameraLensDirection.front)
        .firstOrNull;
    if (front == null) {
      throw const FaceCameraException(FaceCameraFault.unavailable);
    }
    _description = front;
    await _open(front);
  }

  Future<void> _open(CameraDescription description) async {
    // Medium (about 480p) is enough: the gate requires a face over a third of
    // the frame, far above the 112 px crop the server embeds, and keeps both
    // detection and uploads light.
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.nv21,
    );
    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } on CameraException catch (e) {
      await controller.dispose();
      throw FaceCameraException(_fault(e));
    }
    if (_disposed) {
      await controller.dispose();
      return;
    }
    _controller.value = controller;
    await _startStream(controller);
  }

  Future<void> _startStream(CameraController controller) async {
    if (controller.value.isStreamingImages) return;
    try {
      await controller.startImageStream(
        (image) => unawaited(_analyse(image, controller)),
      );
    } on CameraException {
      // Without frames the flow just waits; the user can cancel.
    }
  }

  Future<void> _analyse(CameraImage image, CameraController controller) async {
    if (_busy || _disposed) return;
    final input = _inputImage(image, controller);
    if (input == null) return;
    _busy = true;
    try {
      final faces = await _detector.processImage(input);
      if (_disposed) return;
      final rotation = input.metadata!.rotation;
      final upright =
          rotation == InputImageRotation.rotation90deg ||
              rotation == InputImageRotation.rotation270deg
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());
      _frames.add(
        FaceFrame(
          imageSize: upright,
          brightness: _brightness(image),
          faces: [
            for (final face in faces)
              DetectedFace(
                box: face.boundingBox,
                yaw: face.headEulerAngleY,
                pitch: face.headEulerAngleX,
                roll: face.headEulerAngleZ,
                leftEyeOpen: face.leftEyeOpenProbability,
                rightEyeOpen: face.rightEyeOpenProbability,
              ),
          ],
        ),
      );
    } on Object catch (e) {
      debugPrint('[FaceCamera] detection failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Follows the google_mlkit_commons recipe: Android needs the sensor
  /// rotation compensated for the device orientation (front lens adds it).
  InputImage? _inputImage(CameraImage image, CameraController controller) {
    final sensor = controller.description.sensorOrientation;
    final InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensor);
    } else {
      final device = _deviceRotation[controller.value.deviceOrientation];
      if (device == null) return null;
      rotation = InputImageRotationValue.fromRawValue((sensor + device) % 360);
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    final expected = Platform.isIOS
        ? InputImageFormat.bgra8888
        : InputImageFormat.nv21;
    if (rotation == null || format != expected || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Sampled mean luma; NV21 starts with the Y plane, BGRA is weighted RGB.
  static double? _brightness(CameraImage image) {
    final bytes = image.planes.first.bytes;
    const stride = 97;
    var sum = 0;
    var count = 0;
    if (Platform.isIOS) {
      for (var i = 0; i + 2 < bytes.length; i += stride * 4) {
        sum +=
            (bytes[i + 2] * 299 + bytes[i + 1] * 587 + bytes[i] * 114) ~/ 1000;
        count++;
      }
    } else {
      final luma = image.width * image.height;
      for (var i = 0; i < luma && i < bytes.length; i += stride) {
        sum += bytes[i];
        count++;
      }
    }
    return count == 0 ? null : sum / count;
  }

  @override
  Future<Uint8List> capture() async {
    final controller = _controller.value;
    if (controller == null) {
      throw const FaceCameraException(FaceCameraFault.unavailable);
    }
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      // Biometric data: do not leave the photo in the cache directory.
      unawaited(File(file.path).delete().then((_) {}, onError: (_) {}));
      return bytes;
    } on CameraException {
      throw const FaceCameraException(FaceCameraFault.unavailable);
    } finally {
      if (!_disposed && identical(_controller.value, controller)) {
        await _startStream(controller);
      }
    }
  }

  @override
  Widget buildPreview(BuildContext context) {
    return ValueListenableBuilder<CameraController?>(
      valueListenable: _controller,
      builder: (context, controller, _) {
        final size = controller?.value.previewSize;
        if (controller == null || size == null) {
          return const ColoredBox(color: Colors.black);
        }
        // previewSize is landscape; the screen is portrait.
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.height,
              height: size.width,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pause() async {
    final controller = _controller.value;
    if (controller == null) return;
    _controller.value = null;
    await controller.dispose();
  }

  void _resume() {
    final description = _description;
    if (_disposed || description == null || _controller.value != null) return;
    // ponytail: a failed reopen leaves a black preview; the user cancels and
    // starts again. Surface it as a fault if guards hit it in the field.
    unawaited(_open(description).catchError((Object _) {}));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _lifecycle.dispose();
    await _pause();
    _controller.dispose();
    await _detector.close();
    await _frames.close();
  }

  static FaceCameraFault _fault(CameraException e) => switch (e.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' => FaceCameraFault.permissionDenied,
    _ => FaceCameraFault.unavailable,
  };
}
