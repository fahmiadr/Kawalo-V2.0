import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/screen_brightness_service.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/camera_flash_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockBrightness extends Mock implements ScreenBrightnessService {}

class _FakeCamera extends Fake implements CameraController {
  _FakeCamera({this.rejectFlash = false});

  final bool rejectFlash;
  final List<FlashMode> modes = [];

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    modes.add(mode);
    if (rejectFlash) throw CameraException('flash', 'unsupported');
  }
}

void main() {
  late _MockBrightness brightness;
  late CameraFlashController flash;

  setUp(() {
    brightness = _MockBrightness();
    when(() => brightness.setBrightness(any())).thenAnswer((_) async => true);
    when(() => brightness.resetBrightness()).thenAnswer((_) async => true);
    flash = CameraFlashController(brightnessService: brightness);
  });

  group('nextMode', () {
    test('uses 4-mode cycle with a physical flash', () {
      flash.hasPhysicalFlash = true;
      final seen = <FlashMode>[];
      for (var i = 0; i < 5; i++) {
        flash.mode = flash.nextMode(isScreenFlashOnly: false);
        seen.add(flash.mode);
      }
      expect(seen, [
        FlashMode.auto,
        FlashMode.always,
        FlashMode.torch,
        FlashMode.off,
        FlashMode.auto,
      ]);
    });

    test('uses 2-mode cycle for screen flash only', () {
      expect(flash.nextMode(isScreenFlashOnly: true), FlashMode.always);
      flash.mode = FlashMode.always;
      expect(flash.nextMode(isScreenFlashOnly: true), FlashMode.off);
      flash.mode = FlashMode.torch;
      expect(flash.nextMode(isScreenFlashOnly: true), FlashMode.off);
    });
  });

  group('normalizeModeFor', () {
    test('forces off for a back camera without LED', () {
      flash
        ..mode = FlashMode.always
        ..normalizeModeFor(isFront: false);
      expect(flash.mode, FlashMode.off);
    });

    test('front camera without LED drops torch/auto but keeps always', () {
      flash
        ..mode = FlashMode.torch
        ..normalizeModeFor(isFront: true);
      expect(flash.mode, FlashMode.off);

      flash
        ..mode = FlashMode.auto
        ..normalizeModeFor(isFront: true);
      expect(flash.mode, FlashMode.off);

      flash
        ..mode = FlashMode.always
        ..normalizeModeFor(isFront: true);
      expect(flash.mode, FlashMode.always);
    });

    test('keeps the mode when a physical flash exists', () {
      flash
        ..hasPhysicalFlash = true
        ..mode = FlashMode.torch
        ..normalizeModeFor(isFront: false);
      expect(flash.mode, FlashMode.torch);
    });
  });

  group('isSupported', () {
    test('is optimistic while camera state is unknown', () {
      expect(
        flash.isSupported(
          cameraStateUnknown: true,
          isCurrentCameraFront: false,
        ),
        isTrue,
      );
    });

    test('requires a physical flash or a front camera', () {
      expect(
        flash.isSupported(
          cameraStateUnknown: false,
          isCurrentCameraFront: false,
        ),
        isFalse,
      );
      expect(
        flash.isSupported(
          cameraStateUnknown: false,
          isCurrentCameraFront: true,
        ),
        isTrue,
      );
      flash.hasPhysicalFlash = true;
      expect(
        flash.isSupported(
          cameraStateUnknown: false,
          isCurrentCameraFront: false,
        ),
        isTrue,
      );
    });
  });

  group('checkPhysicalFlashSupport', () {
    test('probes auto then restores off', () async {
      final camera = _FakeCamera();
      expect(await flash.checkPhysicalFlashSupport(camera), isTrue);
      expect(camera.modes, [FlashMode.auto, FlashMode.off]);
    });

    test('returns false when the platform rejects flash', () async {
      expect(
        await flash.checkPhysicalFlashSupport(_FakeCamera(rejectFlash: true)),
        isFalse,
      );
    });
  });

  group('restoreBrightness', () {
    test('restores the saved brightness once, then resets', () async {
      flash.originalBrightness = 0.4;

      await flash.restoreBrightness();
      verify(() => brightness.setBrightness(0.4)).called(1);
      expect(flash.originalBrightness, isNull);

      await flash.restoreBrightness();
      verify(() => brightness.resetBrightness()).called(1);
    });
  });
}
