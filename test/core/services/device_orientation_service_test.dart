import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  group('AospDeviceOrientationStrategy', () {
    const strategy = AospDeviceOrientationStrategy();

    test('calculates portraitUp correctly', () {
      // Resting upright on portrait: y ~ 9.8, x ~ 0, z ~ 0
      final orientation = strategy.calculate(
        x: 0,
        y: 9.8,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientation, equals(DeviceOrientation.portraitUp));
    });

    test('calculates landscapeRight correctly', () {
      // Rotated 90° clockwise: top pointing right, x ~ -9.8, y ~ 0, z ~ 0
      final orientation = strategy.calculate(
        x: -9.8,
        y: 0,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientation, equals(DeviceOrientation.landscapeRight));
    });

    test('calculates portraitDown correctly', () {
      // Upside down: y ~ -9.8, x ~ 0, z ~ 0
      final orientation = strategy.calculate(
        x: 0,
        y: -9.8,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientation, equals(DeviceOrientation.portraitDown));
    });

    test('calculates landscapeLeft correctly', () {
      // Rotated 90° counter-clockwise: top pointing left, x ~ 9.8, y ~ 0, z ~ 0
      final orientation = strategy.calculate(
        x: 9.8,
        y: 0,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientation, equals(DeviceOrientation.landscapeLeft));
    });

    test('returns null when device is lying flat', () {
      // Flat on table face up: z ~ 9.8, x ~ 0, y ~ 0
      final orientation = strategy.calculate(
        x: 0.1,
        y: 0.2,
        z: 9.8,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientation, isNull);
    });

    test('preserves orientation within hysteresis threshold', () {
      // Current is portraitUp. Slight tilt towards landscapeRight (~50°).
      // With default 10° hysteresis, portraitUp sector extends up to 55°.
      // At angle = 50°: x = -sin(50°)*9.8, y = cos(50°)*9.8
      final orientationWithin = strategy.calculate(
        x: -7.5,
        y: 6.3,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientationWithin, equals(DeviceOrientation.portraitUp));

      // Once tilted beyond 55° (e.g. 60°: x = -8.5, y = 4.9)
      final orientationBeyond = strategy.calculate(
        x: -8.5,
        y: 4.9,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientationBeyond, equals(DeviceOrientation.landscapeRight));
    });

    test('supports custom hysteresisDegrees value', () {
      const wideStrategy = AospDeviceOrientationStrategy(hysteresisDegrees: 20);

      // At ~57°, default (10°) would transition. With 20° hysteresis,
      // portraitUp sector extends to 65°, so ~57° stays portraitUp.
      final orientationWithWide = wideStrategy.calculate(
        x: -8.2,
        y: 5.7,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientationWithWide, equals(DeviceOrientation.portraitUp));

      // At ~70°, beyond 65° threshold even with wide hysteresis.
      final orientationBeyondWide = wideStrategy.calculate(
        x: -9.2,
        y: 3.4,
        z: 0,
        current: DeviceOrientation.portraitUp,
      );
      expect(orientationBeyondWide, equals(DeviceOrientation.landscapeRight));
    });

    test('Equatable: equal instances with same hysteresis', () {
      const a = AospDeviceOrientationStrategy();
      const b = AospDeviceOrientationStrategy();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable: unequal instances with different hysteresis', () {
      const a = AospDeviceOrientationStrategy();
      const b = AospDeviceOrientationStrategy(hysteresisDegrees: 20);
      expect(a, isNot(equals(b)));
    });
  });

  group('DefaultDeviceOrientationSensorService', () {
    test('emits changes via stream', () async {
      final controller = StreamController<AccelerometerEvent>();
      final service = DefaultDeviceOrientationSensorService(
        accelerometerStream: controller.stream,
      );

      final received = <DeviceOrientation>[];
      final sub = service.onOrientationChanged.listen(received.add);

      // 1. Emit landscapeLeft: x = 9.8, y = 0, z = 0
      controller.add(AccelerometerEvent(9.8, 0, 0, DateTime.now()));
      await pumpEventQueue();

      expect(received, equals([DeviceOrientation.landscapeLeft]));
      expect(
        service.currentOrientation,
        equals(DeviceOrientation.landscapeLeft),
      );

      // 2. Emit flat: should keep current orientation
      controller.add(AccelerometerEvent(0, 0, 9.8, DateTime.now()));
      await pumpEventQueue();

      expect(received.length, equals(1));
      expect(
        service.currentOrientation,
        equals(DeviceOrientation.landscapeLeft),
      );

      // 3. Emit portraitUp: x = 0, y = 9.8, z = 0
      controller.add(AccelerometerEvent(0, 9.8, 0, DateTime.now()));
      await pumpEventQueue();

      expect(
        received,
        equals([DeviceOrientation.landscapeLeft, DeviceOrientation.portraitUp]),
      );

      await sub.cancel();
      service.dispose();
      await controller.close();
    });

    test(
      'dispose safely prevents late accelerometer events from throwing',
      () async {
        final controller = StreamController<AccelerometerEvent>();
        DefaultDeviceOrientationSensorService(
          accelerometerStream: controller.stream,
        ).dispose();

        // Emit event after dispose
        expect(
          () => controller.add(AccelerometerEvent(9.8, 0, 0, DateTime.now())),
          returnsNormally,
        );
        await pumpEventQueue();

        await controller.close();
      },
    );

    test('supports custom GoF strategy', () async {
      final controller = StreamController<AccelerometerEvent>();
      final customStrategy = _MockStrategy();
      final service = DefaultDeviceOrientationSensorService(
        accelerometerStream: controller.stream,
        strategy: customStrategy,
      );

      final received = <DeviceOrientation>[];
      final sub = service.onOrientationChanged.listen(received.add);

      controller.add(AccelerometerEvent(1, 2, 3, DateTime.now()));
      await pumpEventQueue();

      expect(received, equals([DeviceOrientation.portraitDown]));
      expect(
        service.currentOrientation,
        equals(DeviceOrientation.portraitDown),
      );

      await sub.cancel();
      service.dispose();
      await controller.close();
    });
  });

  group('NoOpDeviceOrientationSensorService', () {
    test('conforms to GoF Null Object contract', () async {
      const noOp = NoOpDeviceOrientationSensorService(
        initialOrientation: DeviceOrientation.landscapeLeft,
      );

      expect(noOp.currentOrientation, equals(DeviceOrientation.landscapeLeft));
      expect(await noOp.onOrientationChanged.isEmpty, isTrue);

      expect(noOp.dispose, returnsNormally);
    });

    test('Equatable: equal instances with same orientation', () {
      const a = NoOpDeviceOrientationSensorService();
      const b = NoOpDeviceOrientationSensorService();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable: unequal instances with different orientation', () {
      const a = NoOpDeviceOrientationSensorService();
      const b = NoOpDeviceOrientationSensorService(
        initialOrientation: DeviceOrientation.landscapeLeft,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DeviceOrientationTurns extension', () {
    test('maps all four orientations to correct turns', () {
      expect(DeviceOrientation.portraitUp.turns, 0.0);
      expect(DeviceOrientation.landscapeLeft.turns, 0.25);
      expect(DeviceOrientation.portraitDown.turns, 0.5);
      expect(DeviceOrientation.landscapeRight.turns, 0.75);
    });

    test('evaluates isPortrait correctly', () {
      expect(DeviceOrientation.portraitUp.isPortrait, isTrue);
      expect(DeviceOrientation.portraitDown.isPortrait, isTrue);
      expect(DeviceOrientation.landscapeLeft.isPortrait, isFalse);
      expect(DeviceOrientation.landscapeRight.isPortrait, isFalse);
    });

    test('evaluates isLandscape correctly', () {
      expect(DeviceOrientation.landscapeLeft.isLandscape, isTrue);
      expect(DeviceOrientation.landscapeRight.isLandscape, isTrue);
      expect(DeviceOrientation.portraitUp.isLandscape, isFalse);
      expect(DeviceOrientation.portraitDown.isLandscape, isFalse);
    });
  });
}

class _MockStrategy implements DeviceOrientationStrategy {
  @override
  DeviceOrientation? calculate({
    required double x,
    required double y,
    required double z,
    required DeviceOrientation current,
  }) {
    return DeviceOrientation.portraitDown;
  }
}
