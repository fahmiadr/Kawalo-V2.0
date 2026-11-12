import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/face/domain/face_frame.dart';
import 'package:kawalo_mobile/features/face/domain/face_quality.dart';

const _size = Size(480, 640);

DetectedFace face({
  Rect box = const Rect.fromLTWH(140, 200, 200, 240),
  double? yaw = 0,
  double? pitch = 0,
  double? roll = 0,
  double? leftEye = 0.9,
  double? rightEye = 0.9,
}) => DetectedFace(
  box: box,
  yaw: yaw,
  pitch: pitch,
  roll: roll,
  leftEyeOpen: leftEye,
  rightEyeOpen: rightEye,
);

FaceFrame frame(List<DetectedFace> faces, {double? brightness = 120}) =>
    FaceFrame(imageSize: _size, faces: faces, brightness: brightness);

void main() {
  group('faceIssue', () {
    test('passes a centred, frontal, well-lit face', () {
      expect(faceIssue(frame([face()])), isNull);
    });

    test('reports each problem in priority order', () {
      expect(faceIssue(frame([])), FaceIssue.noFace);
      expect(faceIssue(frame([face(), face()])), FaceIssue.multipleFaces);
      expect(faceIssue(frame([face()], brightness: 20)), FaceIssue.tooDark);
      expect(
        faceIssue(frame([face(box: const Rect.fromLTWH(200, 280, 80, 100))])),
        FaceIssue.tooFar,
      );
      expect(
        faceIssue(frame([face(box: const Rect.fromLTWH(10, 100, 460, 500))])),
        FaceIssue.tooClose,
      );
      expect(
        faceIssue(frame([face(box: const Rect.fromLTWH(0, 200, 200, 240))])),
        FaceIssue.offCenter,
      );
      expect(faceIssue(frame([face(yaw: 20)])), FaceIssue.tilted);
      expect(faceIssue(frame([face(roll: -15)])), FaceIssue.tilted);
      expect(faceIssue(frame([face(leftEye: 0.1)])), FaceIssue.eyesClosed);
    });

    test('ignores missing angle and eye values', () {
      expect(
        faceIssue(frame([face(yaw: null, leftEye: null)], brightness: null)),
        isNull,
      );
    });
  });
}
