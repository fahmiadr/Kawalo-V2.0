import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/camera_orientation_controller.dart';

class _FakeSensor implements DeviceOrientationSensorService {
  final StreamController<DeviceOrientation> stream =
      StreamController<DeviceOrientation>.broadcast();
  bool disposed = false;

  @override
  DeviceOrientation get currentOrientation => DeviceOrientation.portraitUp;

  @override
  Stream<DeviceOrientation> get onOrientationChanged => stream.stream;

  @override
  void dispose() => disposed = true;
}

void main() {
  late _FakeSensor sensor;
  late CameraOrientationController controller;
  var mounted = true;
  var reducedMotion = false;
  var updates = 0;
  var orientationChanges = 0;

  setUp(() {
    sensor = _FakeSensor();
    mounted = true;
    reducedMotion = false;
    updates = 0;
    orientationChanges = 0;
    controller = CameraOrientationController(
      vsync: const TestVSync(),
      initialOrientation: DeviceOrientation.portraitUp,
      sensorService: sensor,
      isMounted: () => mounted,
      isReducedMotion: () => reducedMotion,
      update: (fn) {
        updates++;
        fn();
      },
      onDeviceOrientationChanged: () => orientationChanges++,
    );
  });

  tearDown(() {
    controller.dispose();
    expect(sensor.disposed, isFalse, reason: 'injected sensor is not owned');
    unawaited(sensor.stream.close());
  });

  group('computeTeleportDuration', () {
    test('scales with the ratio and clamps to 20ms minimum', () {
      expect(
        CameraOrientationController.computeTeleportDuration(1),
        CameraOrientationController.teleportHalfDuration,
      );
      expect(
        CameraOrientationController.computeTeleportDuration(0),
        const Duration(milliseconds: 20),
      );
      expect(
        CameraOrientationController.computeTeleportDuration(5),
        CameraOrientationController.teleportHalfDuration,
      );
    });
  });

  testWidgets('turns accumulate along the shortest path', (tester) async {
    reducedMotion = true;

    controller.updateOrientation(DeviceOrientation.landscapeRight);
    expect(controller.turns, closeTo(-0.25, 1e-9));

    controller.updateOrientation(DeviceOrientation.portraitUp);
    expect(controller.turns, closeTo(0, 1e-9));

    controller.updateOrientation(DeviceOrientation.landscapeLeft);
    expect(controller.turns, closeTo(0.25, 1e-9));
    expect(orientationChanges, 3);
  });

  testWidgets('reduced motion swaps the badge slot immediately', (
    tester,
  ) async {
    reducedMotion = true;

    controller.updateOrientation(DeviceOrientation.landscapeLeft);

    expect(controller.deviceOrientation, DeviceOrientation.landscapeLeft);
    expect(controller.activeBadgeOrientation, DeviceOrientation.landscapeLeft);
  });

  testWidgets('badge slot hands off after the fade-out completes', (
    tester,
  ) async {
    controller.updateOrientation(DeviceOrientation.landscapeLeft);

    expect(controller.deviceOrientation, DeviceOrientation.landscapeLeft);
    expect(controller.activeBadgeOrientation, DeviceOrientation.portraitUp);

    await tester.pumpAndSettle();

    expect(controller.activeBadgeOrientation, DeviceOrientation.landscapeLeft);
  });

  testWidgets('ignores sensor events once unmounted', (tester) async {
    mounted = false;

    sensor.stream.add(DeviceOrientation.landscapeLeft);
    await tester.pump();

    expect(controller.deviceOrientation, DeviceOrientation.portraitUp);
    expect(updates, 0);
  });

  testWidgets('applies sensor events while mounted', (tester) async {
    reducedMotion = true;

    sensor.stream.add(DeviceOrientation.landscapeRight);
    await tester.pump();

    expect(controller.deviceOrientation, DeviceOrientation.landscapeRight);
  });
}
