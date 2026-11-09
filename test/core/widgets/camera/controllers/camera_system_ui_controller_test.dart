import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/camera/controllers/camera_system_ui_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('restore runs once and invokes both callbacks', () {
    final controller = CameraSystemUiController();
    var unlocked = 0;
    var brightnessRestored = 0;

    void restore() => controller.restore(
      unlockCaptureOrientation: () => unlocked++,
      restoreBrightness: () async => brightnessRestored++,
    );

    restore();
    restore();

    expect(controller.hasRestored, isTrue);
    expect(unlocked, 1);
    expect(brightnessRestored, 1);
  });

  test('restore swallows errors from unlockCaptureOrientation', () {
    final controller = CameraSystemUiController();
    var brightnessRestored = 0;

    controller.restore(
      unlockCaptureOrientation: () => throw StateError('disposed'),
      restoreBrightness: () async => brightnessRestored++,
    );

    expect(brightnessRestored, 1);
  });

  test('setup hides the status bar and locks portrait', () {
    final controller = CameraSystemUiController()..setup(isMounted: () => true);

    final methods = calls.map((c) => c.method).toList();
    expect(methods, contains('SystemChrome.setEnabledSystemUIOverlays'));
    expect(methods, contains('SystemChrome.setPreferredOrientations'));

    controller.restore(
      unlockCaptureOrientation: () {},
      restoreBrightness: () async {},
    );
  });
}
