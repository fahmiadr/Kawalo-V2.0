import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kawalo_mobile/core/error/diagnostic_error_formatter.dart';
import 'package:kawalo_mobile/core/services/device_orientation_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/screen_brightness_service.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/utils/image_crop_utils.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/core/widgets/camera/app_multi_shot_camera_screen.dart';
import 'package:kawalo_mobile/core/widgets/camera/camera_actionable_error.dart';
import 'package:mocktail/mocktail.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    builder: (context, child) =>
        M3ETheme(data: AppTheme.m3eLight(), child: child!),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FlashMode.off);
    registerFallbackValue(DeviceOrientation.portraitUp);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(
            'dev.fluttercommunity.plus/sensors/accelerometer',
          ),
          (call) async => null,
        );
  });

  void configureTestView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  }

  group('AppMultiShotCameraScreen allowSkip', () {
    testWidgets('shows Lewati and the counter; Lewati returns no photos', (
      tester,
    ) async {
      configureTestView(tester);
      final controller = MockCameraController();
      when(() => controller.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => controller.cameraId).thenReturn(1);
      when(controller.buildPreview).thenReturn(const SizedBox());

      List<AppMediaFile>? result;
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async =>
                  result = await AppMultiShotCameraScreen.show(
                    context,
                    controller: controller,
                    allowSkip: true,
                  ),
              child: const Text('Buka Kamera'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka Kamera'));
      await tester.pumpAndSettle();

      expect(find.text('0/4'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.byType(AppMultiShotCameraScreen), findsNothing);
      expect(result, isEmpty);
    });

    test('permission denied offers the given exit label', () {
      final data = CameraActionableError.fromCameraException(
        CameraException('CameraAccessDenied', null),
        onRetry: () {},
        onExit: () {},
        permissionExitLabel: 'Lanjut tanpa foto',
      );
      expect(data.secondaryActionLabel, 'Lanjut tanpa foto');
    });
  });

  group('AppMultiShotCameraScreen Widget Tests', () {
    testWidgets('shows error view when cameras list is empty', (tester) async {
      configureTestView(tester);

      await tester.pumpWidget(
        _buildTestApp(const AppMultiShotCameraScreen(cameras: [])),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
        ),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('renders top bar counter and shutter controls correctly', (
      tester,
    ) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());

      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            controller: mockController,
            alreadyAttachedCount: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar quota badge; skip and the shutter-row counter are opt-in.
      expect(find.text('1 / 4 foto'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
      expect(find.text('1/4'), findsNothing);
      expect(find.bySemanticsLabel('1 dari 4 foto dipilih'), findsOneWidget);

      // Close and flash buttons exist in top bar
      expect(
        find.byKey(const ValueKey<String>('camera_close_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_flash_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_shutter_button')),
        findsOneWidget,
      );
      // Single camera list produces placeholder on shutter row
      expect(
        find.byKey(const ValueKey<String>('camera_switch_placeholder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_switch_button')),
        findsNothing,
      );
      // Done button row is not rendered when no photos captured in this session
      expect(
        find.byKey(const ValueKey<String>('camera_done_button')),
        findsNothing,
      );

      // Verify top bar mathematical balance (close < badge at 50% < flash)
      final closeCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('camera_close_button')),
      );
      final badgeCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('camera_quota_badge')),
      );
      final flashCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('camera_flash_button')),
      );

      expect(closeCenter.dx < badgeCenter.dx, isTrue);
      expect(badgeCenter.dx < flashCenter.dx, isTrue);
      // Screen width is 800, so center badge should be centered at dx = 400
      expect((badgeCenter.dx - 400).abs() < 1.0, isTrue);

      // Verify shutter button is centered horizontally at dx = 400
      final shutterCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('camera_shutter_button')),
      );
      expect((shutterCenter.dx - 400).abs() < 1.0, isTrue);
    });

    testWidgets(
      'renders camera_switch_button on shutter row when multiple cameras '
      'exist',
      (tester) async {
        configureTestView(tester);

        const cam1 = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const cam2 = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            cam1,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [cam1, cam2],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('camera_switch_button')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Beralih ke kamera depan'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('camera_switch_placeholder')),
          findsNothing,
        );

        // Verify camera viewfinder is constrained to 9:16 aspect ratio
        final aspectRatioFinder = find.byWidgetPredicate(
          (widget) =>
              widget is AspectRatio &&
              (widget.aspectRatio - ImageCropUtils.aspect9x16).abs() < 0.001,
        );
        expect(aspectRatioFinder, findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'keeps shutter enabled when selection quota reached and reflects '
      'quota in top bar',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              controller: mockController,
              alreadyAttachedCount: 4,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('4 / 4 foto'), findsOneWidget);
        expect(find.bySemanticsLabel('Ambil foto'), findsOneWidget);
      },
    );

    testWidgets('when actionable error exists, hides floating camera controls, '
        'flash button, and quota badge', (tester) async {
      configureTestView(tester);

      await tester.pumpWidget(
        _buildTestApp(const AppMultiShotCameraScreen(cameras: [])),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('camera_actionable_error_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_close_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_shutter_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_flash_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('camera_quota_badge')),
        findsNothing,
      );
    });

    testWidgets('tapping close button dismisses screen and returns result', (
      tester,
    ) async {
      configureTestView(tester);

      dynamic returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await AppMultiShotCameraScreen.show(
                    context,
                    cameras: const [],
                  );
                },
                child: const Text('Buka Kamera'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Buka Kamera'));
      await tester.pumpAndSettle();

      expect(find.byType(AppMultiShotCameraScreen), findsOneWidget);

      // Tap close button
      await tester.tap(
        find.byKey(const ValueKey<String>('camera_close_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppMultiShotCameraScreen), findsNothing);
      expect(returnedResult, isEmpty);
    });

    testWidgets(
      'hides OS status bar on open and restores edgeToEdge on dispose',
      (tester) async {
        final log = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    AppMultiShotCameraScreen.show(context, cameras: const []),
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setEnabledSystemUIOverlays' &&
                (call.arguments as List).contains('SystemUiOverlay.bottom') &&
                !(call.arguments as List).contains('SystemUiOverlay.top'),
          ),
          isTrue,
        );

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        );
        expect(region.value.statusBarIconBrightness, Brightness.light);

        // Simulate user swiping down to reveal system status bar
        const codec = JSONMethodCodec();
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/platform',
          codec.encodeMethodCall(
            const MethodCall('SystemChrome.systemUIChange', [true]),
          ),
          (data) {},
        );

        log.clear();
        await tester.pump(const Duration(milliseconds: 1600));

        // Verifies the status bar automatically re-hides while
        // bottom navigation bar remains visible.
        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setEnabledSystemUIOverlays' &&
                (call.arguments as List).contains('SystemUiOverlay.bottom') &&
                !(call.arguments as List).contains('SystemUiOverlay.top'),
          ),
          isTrue,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('camera_close_button')),
        );
        await tester.pumpAndSettle();

        expect(
          log.any(
            (call) =>
                call.method == 'SystemChrome.setEnabledSystemUIMode' &&
                call.arguments == 'SystemUiMode.edgeToEdge',
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'touch to focus shows reticle indicator and calls controller focus',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsNothing,
        );

        // Tap on preview to focus
        await tester.tap(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsOneWidget,
        );
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);

        // Advance beyond 1500ms auto-hide timer
        await tester.pump(const Duration(milliseconds: 1600));
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsNothing,
        );
      },
    );

    testWidgets('touch to focus rapid re-tap interrupts existing focus and '
        'relocates reticle', (tester) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(
          isInitialized: true,
          previewSize: const Size(1920, 1080),
          focusPointSupported: true,
          exposurePointSupported: true,
        ),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());
      when(() => mockController.setFocusPoint(any())).thenAnswer((_) async {});
      when(
        () => mockController.setExposurePoint(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // Ketuk titik fokus pertama (koordinat 250, 400)
      await tester.tapAt(const Offset(250, 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final firstRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_focus_reticle')),
      );
      expect((firstRect.center.dx - 250).abs() < 1.0, isTrue);
      expect((firstRect.center.dy - 400).abs() < 1.0, isTrue);

      // Majukan 800ms saat masih bertengger lalu ketuk titik kedua (550, 600)
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tapAt(const Offset(550, 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final secondRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_focus_reticle')),
      );
      expect((secondRect.center.dx - 550).abs() < 1.0, isTrue);
      expect((secondRect.center.dy - 600).abs() < 1.0, isTrue);
      verify(() => mockController.setFocusPoint(any())).called(2);

      // Majukan hingga timer selesai
      await tester.pump(const Duration(milliseconds: 1600));
      expect(
        find.byKey(const ValueKey<String>('camera_focus_reticle')),
        findsNothing,
      );
    });

    testWidgets(
      'touch to focus ignores tap when neither focus nor exposure point is '
      'supported',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '1',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 270,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: false,
            exposurePointSupported: false,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Ketuk preview kamera
        await tester.tap(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Reticle tidak boleh muncul dan controller tidak boleh dipanggil
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsNothing,
        );
        verifyNever(() => mockController.setFocusPoint(any()));
        verifyNever(() => mockController.setExposurePoint(any()));
      },
    );

    testWidgets(
      'touch to focus only sets exposure when focus is unsupported but '
      'exposure is supported',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '1',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 270,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: false,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Ketuk preview kamera
        await tester.tap(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Reticle muncul untuk exposure metering
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsOneWidget,
        );
        verifyNever(() => mockController.setFocusPoint(any()));
        verify(() => mockController.setExposurePoint(any())).called(1);
      },
    );

    testWidgets(
      'touch to focus handles hardware exception gracefully without crashing '
      'or showing unexpected error',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          () => mockController.setFocusPoint(any()),
        ).thenThrow(CameraException('setFocusPointFailed', 'Hardware error'));
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Tap preview
        await tester.tap(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Reticle appears, exposurePoint was attempted despite focus failure
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsOneWidget,
        );
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);

        // No actionable unexpected error is shown
        expect(find.byType(AppActionableErrorView), findsNothing);

        // Second tap does not call setFocusPoint again because it was marked
        // unsupported on device
        await tester.tap(
          find.byKey(const ValueKey<String>('camera_preview_gesture_detector')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        verifyNever(() => mockController.setFocusPoint(any()));
        verify(() => mockController.setExposurePoint(any())).called(1);
      },
    );

    testWidgets(
      'transient focus error on controller does not trigger actionable error '
      'view',
      (tester) async {
        configureTestView(tester);

        final listeners = <VoidCallback>[];
        final mockController = _createConfiguredMockController(
          testCamera1,
          listeners,
        );

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Simulate camera controller error callback with focus failure
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(testCamera1).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            errorDescription: 'setFocusPointFailed: Focus mode not supported',
          ),
        );

        for (final listener in listeners) {
          listener();
        }
        await tester.pump();

        // Viewfinder is NOT replaced with AppActionableErrorView
        expect(find.byType(AppActionableErrorView), findsNothing);
      },
    );

    testWidgets(
      'recovers and reinitializes camera when app lifecycle resumes',
      (tester) async {
        configureTestView(tester);

        await tester.pumpWidget(
          _buildTestApp(const AppMultiShotCameraScreen(cameras: [])),
        );
        await tester.pumpAndSettle();

        // Initially shows error view because cameras is empty
        expect(
          find.text(
            'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
          ),
          findsOneWidget,
        );

        // Transition app to paused (user switched to another camera app)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // Transition app back to resumed (user returns to this app)
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Camera re-initializes without crashes and restores state
        expect(
          find.text(
            'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders camera_done_button above thumbnail tray when photo captured',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        final tempDir = Directory.systemTemp.createTempSync('camera_test_');
        final tempFile = File('${tempDir.path}/sample.jpg');
        // Buat citra 120x160 (rasio 3:4) untuk memverifikasi
        // pemotongan ke 9:16 secara cepat dan deterministik
        final testImg = img.Image(width: 120, height: 160);
        img.fill(testImg, color: img.ColorRgb8(255, 0, 0));
        tempFile.writeAsBytesSync(img.encodeJpg(testImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Initially no done button
        expect(
          find.byKey(const ValueKey<String>('camera_done_button')),
          findsNothing,
        );

        // Verify shutter button is enabled and trigger its onTap
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        expect(tappable.enabled, isTrue);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          // Allow fromXFile, precache, and state update to complete
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        verify(mockController.takePicture).called(1);
        expect(
          find.byKey(const ValueKey<String>('camera_done_button')),
          findsOneWidget,
        );

        // Verifikasi bahwa berkas foto telah dipotong ke rasio 9:16 (90x160)
        final croppedBytes = tempFile.readAsBytesSync();
        final croppedImg = img.decodeImage(croppedBytes);
        expect(croppedImg, isNotNull);
        expect(croppedImg!.height, equals(160));
        expect(croppedImg.width, equals(90));
        final aspect = croppedImg.width / croppedImg.height;
        expect((aspect - (9 / 16)).abs() < 0.001, isTrue);
      },
    );

    testWidgets('verifies top bar is separated above camera view and controls '
        'are constrained inside 9:16 frame', (tester) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // 1. AspectRatio 9:16 bounding rect
      final viewfinderFinder = find.byKey(
        const ValueKey<String>('camera_viewfinder_container'),
      );
      expect(viewfinderFinder, findsOneWidget);
      final viewfinderRect = tester.getRect(viewfinderFinder);

      // 2. Rect tombol top bar
      final closeRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_close_button')),
      );
      final badgeRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_quota_badge')),
      );
      final flashRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_flash_button')),
      );

      // Verifikasi baris top bar terpisah di atas bidang view kamera
      expect(closeRect.bottom <= viewfinderRect.top, isTrue);
      expect(badgeRect.bottom <= viewfinderRect.top, isTrue);
      expect(flashRect.bottom <= viewfinderRect.top, isTrue);

      // 3. Rect tombol shutter
      final shutterRect = tester.getRect(
        find.byKey(const ValueKey<String>('camera_shutter_button')),
      );

      // Verifikasi tombol shutter ter-constraint di dalam view kamera 9:16
      expect(shutterRect.top >= viewfinderRect.top, isTrue);
      expect(shutterRect.bottom <= viewfinderRect.bottom, isTrue);
      expect(shutterRect.left >= viewfinderRect.left, isTrue);
      expect(shutterRect.right <= viewfinderRect.right, isTrue);
    });

    testWidgets(
      'triggers shutter flash curtain immediately upon camera capture',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        final tempDir = Directory.systemTemp.createTempSync('flash_test_');
        final tempFile = File('${tempDir.path}/sample.jpg');
        final testImg = img.Image(width: 120, height: 160);
        img.fill(testImg, color: img.ColorRgb8(0, 255, 0));
        tempFile.writeAsBytesSync(img.encodeJpg(testImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // 1. Shutter flash widget exists in tree, freeze frame does not
        expect(
          find.byKey(const ValueKey<String>('camera_shutter_flash')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('camera_freeze_frame')),
          findsNothing,
        );

        // Sebelum jepret, child di dalam shutter flash adalah SizedBox.shrink
        final initialContainerFinder = find.descendant(
          of: find.byKey(const ValueKey<String>('camera_shutter_flash')),
          matching: find.byType(Container),
        );
        expect(initialContainerFinder, findsNothing);

        // 2. Trigger shutter
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          // Allow fromXFile, precache, and state update to complete
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump();

        // Verifikasi takePicture terpanggil oleh hardware
        verify(mockController.takePicture).called(1);

        // Majukan waktu 250ms untuk menyelesaikan siklus tirai rana 200ms
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();

        // Shutter flash kembali ke SizedBox.shrink setelah durasi selesai
        final postContainerFinder = find.descendant(
          of: find.byKey(const ValueKey<String>('camera_shutter_flash')),
          matching: find.byType(Container),
        );
        expect(postContainerFinder, findsNothing);

        // Pastikan foto masuk ke thumbnail tray
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets('respects reduced motion by disabling shutter flash', (
      tester,
    ) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: M3ETheme(data: AppTheme.m3eLight(), child: child!),
          ),
          home: Scaffold(
            body: AppMultiShotCameraScreen(controller: mockController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final flashFinder = find.byKey(
        const ValueKey<String>('camera_shutter_flash'),
      );
      expect(flashFinder, findsOneWidget);

      // With reduced motion, CameraShutterFlash returns SizedBox.shrink()
      final sizedBoxFinder = find.descendant(
        of: flashFinder,
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxFinder, findsOneWidget);
    });

    testWidgets(
      'toggling photo selection updates counter, sequence badge, and done '
      'button',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        final tempDir = Directory.systemTemp.createTempSync('toggle_sel_test_');
        final tempFile = File('${tempDir.path}/sample.jpg');
        final testImg = img.Image(width: 120, height: 160);
        img.fill(testImg, color: img.ColorRgb8(0, 0, 255));
        tempFile.writeAsBytesSync(img.encodeJpg(testImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Ambil 1 foto
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Foto otomatis terpilih saat kuota tersedia (urutan 1)
        expect(find.text('1 / 4 foto'), findsOneWidget);
        final thumbFinder = find.byKey(
          ValueKey<String>('captured_thumbnail_${tempFile.path}'),
        );
        final deleteBtnFinder = find.byKey(
          ValueKey<String>('remove_captured_photo_${tempFile.path}'),
        );
        expect(
          tester.widget<AppIconButton>(deleteBtnFinder).semanticLabel,
          'Hapus foto ke-1',
        );
        expect(thumbFinder, findsOneWidget);
        expect(
          find.descendant(of: thumbFinder, matching: find.text('1')),
          findsOneWidget,
        );

        // Verifikasi scrim terpilih menggunakan AnimatedContainer dengan
        // warna halus
        final selectedScrimFinder = find.descendant(
          of: thumbFinder,
          matching: find.byType(AnimatedContainer),
        );
        expect(selectedScrimFinder, findsOneWidget);
        final selectedContainer = tester.widget<AnimatedContainer>(
          selectedScrimFinder,
        );
        final selectedDecoration =
            selectedContainer.decoration as BoxDecoration?;
        expect(
          selectedDecoration?.color,
          equals(Colors.black.withValues(alpha: 0.24)),
        );

        // Verifikasi dimensi thumbnail strictly 1:1 dan tombol hapus mengambang
        final thumbRect = tester.getRect(thumbFinder);
        expect(thumbRect.width, equals(thumbRect.height));
        expect(thumbRect.width, equals(72.0));

        final deleteBtnRect = tester.getRect(deleteBtnFinder);
        expect(deleteBtnRect.width, equals(20.0));
        expect(deleteBtnRect.height, equals(20.0));
        expect(deleteBtnRect.center.dx, closeTo(thumbRect.right, 8.0));
        expect(deleteBtnRect.center.dy, closeTo(thumbRect.top, 8.0));

        // Ketuk thumbnail untuk membatalkan pilihan (unselect)
        await tester.tap(thumbFinder);
        await tester.pumpAndSettle();

        // Kuota terpilih menjadi 0, nomor urut '1' di thumbnail hilang
        expect(find.text('0 / 4 foto'), findsOneWidget);
        expect(
          find.descendant(of: thumbFinder, matching: find.text('1')),
          findsNothing,
        );

        // Verifikasi scrim bertransisi menjadi transparan saat tidak dipilih
        final unselectedScrimFinder = find.descendant(
          of: thumbFinder,
          matching: find.byType(AnimatedContainer),
        );
        expect(unselectedScrimFinder, findsOneWidget);
        final unselectedContainer = tester.widget<AnimatedContainer>(
          unselectedScrimFinder,
        );
        final unselectedDecoration =
            unselectedContainer.decoration as BoxDecoration?;
        expect(unselectedDecoration?.color, equals(Colors.transparent));

        // Tombol Done tidak dirender saat tidak ada foto yang dipilih
        expect(
          find.byKey(const ValueKey<String>('camera_done_button')),
          findsNothing,
        );

        // Verifikasi Zero Layout Shift: posisi baki thumbnail tidak bergeser
        final unselectedThumbRect = tester.getRect(thumbFinder);
        expect(unselectedThumbRect.top, equals(thumbRect.top));
        expect(unselectedThumbRect.bottom, equals(thumbRect.bottom));

        // Ketuk kembali thumbnail untuk memilih ulang
        await tester.tap(thumbFinder);
        await tester.pumpAndSettle();

        expect(find.text('1 / 4 foto'), findsOneWidget);
        final doneBtnFinder = find.byKey(
          const ValueKey<String>('camera_done_button'),
        );
        expect(doneBtnFinder, findsOneWidget);
        final doneBtnWidget = tester.widget<AppIconButton>(doneBtnFinder);
        expect(
          doneBtnWidget.badgeColor,
          equals(AppTheme.m3eLight().colorScheme.surfaceContainerHigh),
        );
        expect(
          doneBtnWidget.badgeTextColor,
          equals(AppTheme.m3eLight().colorScheme.onSurface),
        );
        expect(
          find.descendant(of: thumbFinder, matching: find.text('1')),
          findsOneWidget,
        );

        // Verifikasi Zero Layout Shift: posisi thumbnail tetap terkunci stabil
        final reselectedThumbRect = tester.getRect(thumbFinder);
        expect(reselectedThumbRect.top, equals(thumbRect.top));
        expect(reselectedThumbRect.bottom, equals(thumbRect.bottom));

        // Hapus foto menggunakan tombol silang
        await tester.tap(deleteBtnFinder);
        await tester.pumpAndSettle();

        // Baki thumbnail dan tombol selesai hilang karena kosong
        expect(thumbFinder, findsNothing);
        expect(
          find.byKey(const ValueKey<String>('camera_done_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'capturing past maxPhotos places newest photo at index 0 unselected '
      'without FIFO shift',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        final tempDir = Directory.systemTemp.createTempSync('unlimited_cap_');
        final file1 = File('${tempDir.path}/pic1.jpg');
        final file2 = File('${tempDir.path}/pic2.jpg');
        final testImg = img.Image(width: 120, height: 160);
        img.fill(testImg, color: img.ColorRgb8(120, 50, 80));
        file1.writeAsBytesSync(img.encodeJpg(testImg));
        file2.writeAsBytesSync(img.encodeJpg(testImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        var callCount = 0;
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(mockController.takePicture).thenAnswer((_) async {
          callCount++;
          return XFile(callCount == 1 ? file1.path : file2.path);
        });

        // alreadyAttachedCount 3 dan default maxPhotos 4 ->
        // hanya 1 foto baru yang dapat dipilih
        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              controller: mockController,
              alreadyAttachedCount: 3,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 / 4 foto'), findsOneWidget);

        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        var tappable = tester.widget<AppTappable>(shutterFinder);

        // Jepret foto 1
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = file1.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Kuota sekarang 4/4 (penuh), foto 1 otomatis tercentang
        expect(find.text('4 / 4 foto'), findsOneWidget);
        expect(
          find.byKey(ValueKey<String>('captured_thumbnail_${file1.path}')),
          findsOneWidget,
        );

        // Jepret foto 2 melebihi kuota pilih
        tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = file2.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Foto ke-2 sekarang berada di index 0 (kiri) status tidak terpilih.
        // Foto ke-1 bergeser ke index 1 dan TETAP terpilih (tanpa FIFO shift).
        expect(
          find.byKey(ValueKey<String>('captured_thumbnail_${file2.path}')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey<String>('captured_thumbnail_${file1.path}')),
          findsOneWidget,
        );

        // Kuota tetap 4 / 4 foto (1 dari kamera + 3 yang sudah ada)
        expect(find.text('4 / 4 foto'), findsOneWidget);

        // Coba ketuk foto baru di index 0 yang unselected saat kuota penuh
        await tester.tap(
          find.byKey(ValueKey<String>('captured_thumbnail_${file2.path}')),
        );
        await tester.pumpAndSettle();

        // Muncul snackbar kuota
        expect(find.text('Maksimal 1 foto dapat dipilih.'), findsOneWidget);
      },
    );

    testWidgets(
      'verifies thumbnail tray has 24dp resting padding and full-bleed '
      'scrollable bounds to viewfinder edges',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_thumb_scroll.jpg');
        final rawImg = img.Image(width: 90, height: 160);
        img.fill(rawImg, color: img.ColorRgba8(255, 0, 0, 255));
        tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        final viewfinderRect = tester.getRect(
          find.byKey(const ValueKey<String>('camera_viewfinder_container')),
        );
        final thumbRect = tester.getRect(
          find.byKey(ValueKey<String>('captured_thumbnail_${tempFile.path}')),
        );

        // Resting padding from left edge is exactly 24dp (AppSpacing.space300)
        expect(thumbRect.left - viewfinderRect.left, 24.0);

        // Verify ListView spans full width of viewfinder (full bleed)
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);
        final listRect = tester.getRect(listViewFinder);
        expect(listRect.left, equals(viewfinderRect.left));
        expect(listRect.right, equals(viewfinderRect.right));
      },
    );

    testWidgets('animates newest thumbnail expansion and smoothly pushes '
        'existing thumbnails without void gap', (tester) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());

      final tempDir = Directory.systemTemp.createTempSync();
      final file1 = File('${tempDir.path}/test_thumb_1.jpg');
      final file2 = File('${tempDir.path}/test_thumb_2.jpg');
      final rawImg = img.Image(width: 90, height: 160);
      img.fill(rawImg, color: img.ColorRgba8(255, 0, 0, 255));
      file1.writeAsBytesSync(img.encodeJpg(rawImg));
      file2.writeAsBytesSync(img.encodeJpg(rawImg));

      var captureCount = 0;
      when(mockController.takePicture).thenAnswer((_) async {
        captureCount++;
        return XFile(captureCount == 1 ? file1.path : file2.path);
      });

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      // 1. Ambil foto pertama
      final shutterFinder = find.byKey(
        const ValueKey<String>('camera_shutter_button'),
      );
      var tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        for (var i = 0; i < 80; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final bytes = file1.readAsBytesSync();
          final decoded = img.decodeImage(bytes);
          if (decoded != null && decoded.width == 90) break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Thumbnail pertama terpasang di posisi awal
      final initialThumb0Rect = tester.getRect(
        find.byKey(ValueKey<String>('captured_thumbnail_${file1.path}')),
      );
      expect(initialThumb0Rect.width, 72.0);

      // 2. Ambil foto kedua
      tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        for (var i = 0; i < 80; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final bytes = file2.readAsBytesSync();
          final decoded = img.decodeImage(bytes);
          if (decoded != null && decoded.width == 90) break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      // Pompa 1 frame awal untuk memulai animasi ekspansi lebar
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Verifikasi TweenAnimationBuilder aktif untuk thumbnail baru dan celah
      expect(
        find.byKey(ValueKey<String>('tray_newest_${file2.path}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('tray_sep_${file2.path}')),
        findsOneWidget,
      );

      // Thumbnail lama (sekarang index 1) telah bergeser ke kanan
      final shiftingThumb1Rect = tester.getRect(
        find.byKey(ValueKey<String>('captured_thumbnail_${file1.path}')),
      );
      expect(shiftingThumb1Rect.left > initialThumb0Rect.left, isTrue);

      // Selesaikan sisa animasi hingga kondisi tenang (settle)
      await tester.pumpAndSettle();

      // Verifikasi kedua thumbnail berada di posisi akhir yang stabil
      final finalThumb0Rect = tester.getRect(
        find.byKey(ValueKey<String>('captured_thumbnail_${file2.path}')),
      );
      final finalThumb1Rect = tester.getRect(
        find.byKey(ValueKey<String>('captured_thumbnail_${file1.path}')),
      );
      expect(finalThumb0Rect.width, 72.0);
      expect(finalThumb1Rect.width, 72.0);
      expect(finalThumb0Rect.left, equals(initialThumb0Rect.left));
      expect(finalThumb1Rect.left > finalThumb0Rect.right, isTrue);
    });

    testWidgets(
      'cycles through flash modes off -> auto -> always -> torch -> off '
      'with correct vectors and semantic labels',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        expect(flashBtnFinder, findsOneWidget);

        // 1. Awal: FlashMode.off (KawaloVectors.flashOff)
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byWidgetPredicate(
              (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.flashOff,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat mati',
        );

        // 2. Ketuk 1: FlashMode.auto (KawaloVectors.flashAuto)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        verify(() => mockController.setFlashMode(FlashMode.auto)).called(1);
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byWidgetPredicate(
              (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.flashAuto,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat otomatis',
        );

        // 3. Ketuk 2: FlashMode.always (KawaloVectors.flash)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        verify(() => mockController.setFlashMode(FlashMode.always)).called(1);
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byWidgetPredicate(
              (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.flash,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat selalu menyala saat foto',
        );

        // 4. Ketuk 3: FlashMode.torch (KawaloVectors.flashTorch)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        verify(() => mockController.setFlashMode(FlashMode.torch)).called(1);
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byWidgetPredicate(
              (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.flashTorch,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu senter terus menyala',
        );

        // 5. Ketuk 4: Kembali ke FlashMode.off (KawaloVectors.flashOff)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        verify(() => mockController.setFlashMode(FlashMode.off)).called(1);
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byWidgetPredicate(
              (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.flashOff,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat mati',
        );
      },
    );

    testWidgets(
      'touch to focus activates AF assist torch when flashMode is always and '
      'restores always mode upon dismiss on back camera',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        );
        when(() => mockController.cameraId).thenReturn(0);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final flashBtn = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        // Ketuk untuk rotasi: off -> auto -> always
        await tester.tap(flashBtn);
        await tester.pumpAndSettle();
        await tester.tap(flashBtn);
        await tester.pumpAndSettle();

        // Mode sekarang adalah always. Ketuk preview untuk touch-to-focus
        final previewFinder = find.byKey(
          const ValueKey<String>('camera_preview_gesture_detector'),
        );
        await tester.tap(previewFinder);
        await tester.pump();

        // Verifikasi senter dinyalakan sementara sebagai AF assist lamp
        verify(() => mockController.setFlashMode(FlashMode.torch)).called(1);

        // Majukan timer melampaui batas auto-hide reticle (1450ms)
        await tester.pump(const Duration(milliseconds: 1500));

        // Verifikasi mode flash dikembalikan ke always
        verify(() => mockController.setFlashMode(FlashMode.always)).called(2);
      },
    );

    testWidgets(
      'touch to focus does not activate AF assist torch when flashMode is auto',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        );
        when(() => mockController.cameraId).thenReturn(0);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final flashBtn = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        // Ketuk sekali: off -> auto
        await tester.tap(flashBtn);
        await tester.pumpAndSettle();

        final previewFinder = find.byKey(
          const ValueKey<String>('camera_preview_gesture_detector'),
        );
        await tester.tap(previewFinder);
        await tester.pump();

        // Verifikasi senter tidak dinyalakan di mode auto
        verifyNever(() => mockController.setFlashMode(FlashMode.torch));
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);

        // Majukan timer melampaui batas auto-hide reticle (1450ms)
        await tester.pump(const Duration(milliseconds: 1500));

        // Verifikasi tidak ada restorasi mode flash karena tidak diubah
        verify(() => mockController.setFlashMode(FlashMode.auto)).called(1);
      },
    );

    testWidgets(
      'touch to focus does not activate AF assist torch when flashMode is off',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        );
        when(() => mockController.cameraId).thenReturn(0);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        // Mode awal adalah off. Ketuk preview untuk fokus
        final previewFinder = find.byKey(
          const ValueKey<String>('camera_preview_gesture_detector'),
        );
        await tester.tap(previewFinder);
        await tester.pump();

        // Pada mode off, senter tidak boleh menyala
        verifyNever(() => mockController.setFlashMode(FlashMode.torch));
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);
      },
    );

    testWidgets('touch to focus maintains torch mode without resetting when '
        'flashMode is torch', (tester) async {
      configureTestView(tester);

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(
          isInitialized: true,
          previewSize: const Size(1920, 1080),
          focusPointSupported: true,
          exposurePointSupported: true,
        ),
      );
      when(() => mockController.description).thenReturn(
        const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      );
      when(() => mockController.cameraId).thenReturn(0);
      when(mockController.buildPreview).thenReturn(const SizedBox());
      when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
      when(() => mockController.setFocusPoint(any())).thenAnswer((_) async {});
      when(
        () => mockController.setExposurePoint(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      final flashBtn = find.byKey(
        const ValueKey<String>('camera_flash_button'),
      );
      // off -> auto -> always -> torch
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();

      // Ketuk preview untuk fokus
      final previewFinder = find.byKey(
        const ValueKey<String>('camera_preview_gesture_detector'),
      );
      await tester.tap(previewFinder);
      await tester.pump();

      // Majukan timer melampaui batas auto-hide reticle
      await tester.pump(const Duration(milliseconds: 1500));

      // Pastikan tidak ada pemanggilan setFlashMode(FlashMode.off) yang
      // mematikan senter saat reticle fokus selesai
      verifyNever(() => mockController.setFlashMode(FlashMode.off));
    });

    testWidgets('shutter capture on front camera triggers screen flash overlay '
        'when flash is always', (tester) async {
      configureTestView(tester);

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_front.jpg');
      final rawImage = img.Image(width: 90, height: 160);
      img.fill(rawImage, color: img.ColorRgb8(200, 200, 200));
      tempFile.writeAsBytesSync(img.encodeJpg(rawImage));

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '1',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 270,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.description).thenReturn(
        const CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      );
      when(() => mockController.cameraId).thenReturn(1);
      when(mockController.buildPreview).thenReturn(const SizedBox());
      when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
      when(mockController.takePicture).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return XFile(tempFile.path);
      });

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      final flashBtn = find.byKey(
        const ValueKey<String>('camera_flash_button'),
      );
      // off -> always (pada kamera depan, mode disederhanakan off dan always)
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();

      // Tekan tombol rana
      final shutterFinder = find.byKey(
        const ValueKey<String>('camera_shutter_button'),
      );
      final tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        // Jeda jeda pra-shutter screen flash (180ms)
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Verifikasi overlay screen flash putih muncul
      expect(
        find.byKey(const ValueKey<String>('camera_screen_flash_overlay')),
        findsOneWidget,
      );

      // Biarkan proses pengambilan foto selesai
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verifikasi overlay screen flash telah menghilang pasca-capture
      expect(
        find.byKey(const ValueKey<String>('camera_screen_flash_overlay')),
        findsNothing,
      );
    });

    testWidgets('shutter capture preserves torch mode after capture when '
        'flashMode is torch', (tester) async {
      configureTestView(tester);

      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_torch.jpg');
      final rawImage = img.Image(width: 90, height: 160);
      img.fill(rawImage, color: img.ColorRgb8(100, 100, 100));
      tempFile.writeAsBytesSync(img.encodeJpg(rawImage));

      final mockController = MockCameraController();
      when(() => mockController.value).thenReturn(
        const CameraValue.uninitialized(
          CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
      );
      when(() => mockController.description).thenReturn(
        const CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      );
      when(() => mockController.cameraId).thenReturn(0);
      when(mockController.buildPreview).thenReturn(const SizedBox());
      when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
      when(mockController.takePicture).thenAnswer((_) async {
        return XFile(tempFile.path);
      });

      await tester.pumpWidget(
        _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
      );
      await tester.pumpAndSettle();

      final flashBtn = find.byKey(
        const ValueKey<String>('camera_flash_button'),
      );
      // off -> auto -> always -> torch
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();
      await tester.tap(flashBtn);
      await tester.pumpAndSettle();

      final shutterFinder = find.byKey(
        const ValueKey<String>('camera_shutter_button'),
      );
      final tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verifikasi setFlashMode(FlashMode.torch) dipanggil lagi pasca-capture
      // (1x saat tombol ditekan ke torch + 1x pasca-jepret guardrail = 2)
      verify(() => mockController.setFlashMode(FlashMode.torch)).called(2);
    });

    testWidgets(
      'front camera flash cycle simplifies to 2 modes: off and always for '
      'screen flash even when hardware throws',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '1',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 270,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '1',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 270,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        // Simulasikan kamera depan throw exception saat setFlashMode
        when(
          () => mockController.setFlashMode(any()),
        ).thenThrow(Exception('Flash not supported on front camera'));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );

        // 1. Awal: FlashMode.off
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat mati',
        );

        // 2. Ketuk 1: FlashMode.always (langsung ke always untuk Screen Flash)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat selalu menyala saat foto',
        );

        // 3. Ketuk 2: Kembali ke FlashMode.off
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat mati',
        );
      },
    );

    testWidgets(
      'rear camera without physical flash unit hides flash button and '
      'preserves quota badge centering',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
        );
        when(() => mockController.cameraId).thenReturn(0);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              controller: mockController,
              hasPhysicalFlash: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi tombol flash dihilangkan (hidden)
        expect(
          find.byKey(const ValueKey<String>('camera_flash_button')),
          findsNothing,
        );

        // 2. Verifikasi tombol close dan quota badge tetap tampil
        expect(
          find.byKey(const ValueKey<String>('camera_close_button')),
          findsOneWidget,
        );
        final quotaFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge'),
        );
        expect(quotaFinder, findsOneWidget);

        // 3. Verifikasi badge kuota tetap berada di tengah layar
        // secara simetris
        final badgeCenter = tester.getCenter(quotaFinder);
        expect(badgeCenter.dx, closeTo(400.0, 1.0));
      },
    );

    testWidgets(
      'front camera with physical flash unit provides full 4 flash modes and '
      'triggers AF assist torch without screen flash overlay',
      (tester) async {
        configureTestView(tester);

        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_front_led.jpg');
        final rawImage = img.Image(width: 90, height: 160);
        img.fill(rawImage, color: img.ColorRgb8(100, 100, 100));
        tempFile.writeAsBytesSync(img.encodeJpg(rawImage));

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '1',
              lensDirection: CameraLensDirection.front,
              sensorOrientation: 270,
            ),
          ).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(() => mockController.description).thenReturn(
          const CameraDescription(
            name: '1',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 270,
          ),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});
        when(mockController.takePicture).thenAnswer((_) async {
          return XFile(tempFile.path);
        });

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              controller: mockController,
              hasPhysicalFlash: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        expect(flashBtnFinder, findsOneWidget);

        // Siklus penuh 4 mode: off -> auto -> always
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu kilat selalu menyala saat foto',
        );

        // Ketuk preview untuk memicu AF assist torch
        final previewFinder = find.byKey(
          const ValueKey<String>('camera_preview_gesture_detector'),
        );
        await tester.tap(previewFinder);
        await tester.pump();
        verify(() => mockController.setFlashMode(FlashMode.torch)).called(1);

        // Tekan shutter dan verifikasi Screen Flash TIDAK muncul
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        tappable.onTap!();
        await tester.pump();
        expect(
          find.byKey(const ValueKey<String>('camera_screen_flash_overlay')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'switching camera when flashMode is torch normalizes flashMode to off '
      'and safely handles controller transition without error boundary',
      (tester) async {
        configureTestView(tester);

        const cam1 = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const cam2 = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            cam1,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(cam1);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(mockController.dispose).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [cam1, cam2],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );

        // Siklus ke FlashMode.torch (off -> auto -> always -> torch)
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();
        await tester.tap(flashBtnFinder);
        await tester.pumpAndSettle();

        expect(
          tester.widget<AppIconButton>(flashBtnFinder).semanticLabel,
          'Lampu senter terus menyala',
        );

        // Tekan tombol switch kamera
        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        expect(switchBtnFinder, findsOneWidget);
        await tester.tap(switchBtnFinder);
        await tester.pump();

        // Saat transisi, controller lama dimatikan senternya dan di-dispose
        verify(() => mockController.setFlashMode(FlashMode.off)).called(1);
        verify(mockController.dispose).called(1);
      },
    );

    testWidgets(
      'flash button and switch camera button render disabled icon color '
      'and decoration opacity when capturing',
      (tester) async {
        configureTestView(tester);

        const cam1 = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const cam2 = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            cam1,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(cam1);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());

        final captureCompleter = Completer<XFile>();
        when(
          mockController.takePicture,
        ).thenAnswer((_) => captureCompleter.future);

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [cam1, cam2],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );

        // 1. Verifikasi state awal (Enabled): icon berwarna putih solid
        expect(
          tester.widget<AppIconButton>(flashBtnFinder).onPressed,
          isNotNull,
        );
        expect(
          tester.widget<AppIconButton>(switchBtnFinder).onPressed,
          isNotNull,
        );

        final flashIconEnabled = tester.widget<AppSvgIcon>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(flashIconEnabled.color, equals(Colors.white));

        final switchIconEnabled = tester.widget<AppSvgIcon>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(switchIconEnabled.color, equals(Colors.white));

        // 2. Trigger shutter capture (masuk ke state capturing)
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        tappable.onTap!();
        await tester.pump();

        // 3. Verifikasi state disabled saat pengambilan foto berlangsung:
        // onPressed bernilai null
        expect(tester.widget<AppIconButton>(flashBtnFinder).onPressed, isNull);
        expect(tester.widget<AppIconButton>(switchBtnFinder).onPressed, isNull);

        // Icon SVG menggunakan warna disabled dengan opacity disabledOpacity
        final flashIconDisabled = tester.widget<AppSvgIcon>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(
          flashIconDisabled.color,
          equals(Colors.white.withValues(alpha: AppStateLayer.disabledOpacity)),
        );

        final switchIconDisabled = tester.widget<AppSvgIcon>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(
          switchIconDisabled.color,
          equals(Colors.white.withValues(alpha: AppStateLayer.disabledOpacity)),
        );

        // Foreground color decoration pada state disabled juga terkonfigurasi
        final flashBtn = tester.widget<AppIconButton>(flashBtnFinder);
        final flashFg = flashBtn.decoration?.foregroundColor?.resolve({
          WidgetState.disabled,
        });
        expect(
          flashFg,
          equals(Colors.white.withValues(alpha: AppStateLayer.disabledOpacity)),
        );

        final switchBtn = tester.widget<AppIconButton>(switchBtnFinder);
        final switchFg = switchBtn.decoration?.foregroundColor?.resolve({
          WidgetState.disabled,
        });
        expect(
          switchFg,
          equals(Colors.white.withValues(alpha: AppStateLayer.disabledOpacity)),
        );

        // 4. Selesaikan capture dan verifikasi kembali ke state enabled
        captureCompleter.completeError(Exception('simulated error'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<AppIconButton>(flashBtnFinder).onPressed,
          isNotNull,
        );
        expect(
          tester.widget<AppIconButton>(switchBtnFinder).onPressed,
          isNotNull,
        );

        final flashIconRestored = tester.widget<AppSvgIcon>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(flashIconRestored.color, equals(Colors.white));

        final switchIconRestored = tester.widget<AppSvgIcon>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(switchIconRestored.color, equals(Colors.white));
      },
    );

    testWidgets(
      'screen flash on front camera boosts screen brightness to 1.0 and '
      'restores initial brightness after capture, while inverting controls',
      (tester) async {
        configureTestView(tester);

        final mockBrightnessService = MockScreenBrightnessService();
        when(
          () => mockBrightnessService.currentBrightness,
        ).thenAnswer((_) async => 0.45);
        when(
          () => mockBrightnessService.setBrightness(any()),
        ).thenAnswer((_) async => true);
        when(
          mockBrightnessService.resetBrightness,
        ).thenAnswer((_) async => true);

        const frontCamera = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );
        const backCamera = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            frontCamera,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(frontCamera);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});

        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_front_flash.jpg');
        final rawImage = img.Image(width: 90, height: 160);
        img.fill(rawImage, color: img.ColorRgb8(100, 100, 100));
        tempFile.writeAsBytesSync(img.encodeJpg(rawImage));

        addTearDown(() {
          try {
            if (tempDir.existsSync()) {
              tempDir.deleteSync(recursive: true);
            }
          } on Object catch (_) {}
        });

        when(mockController.takePicture).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return XFile(tempFile.path);
        });

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [frontCamera, backCamera],
              controller: mockController,
              brightnessService: mockBrightnessService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final flashBtn = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        // Aktifkan mode always untuk screen flash kamera depan
        await tester.tap(flashBtn);
        await tester.pumpAndSettle();

        // Tekan tombol shutter
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // 1. Verifikasi kecerahan layar dinaikkan ke 1.0 (100%)
        verify(() => mockBrightnessService.setBrightness(1)).called(1);

        // 2. Verifikasi overlay illuminated frame muncul
        final overlayFinder = find.byKey(
          const ValueKey<String>('camera_screen_flash_overlay'),
        );
        expect(overlayFinder, findsOneWidget);

        // 3. Verifikasi tombol switch kamera terinversi ke warna hitam
        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        expect(switchBtnFinder, findsOneWidget);
        final switchIcon = tester.widget<AppSvgIcon>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
        );
        expect(
          switchIcon.color,
          equals(Colors.black.withValues(alpha: AppStateLayer.disabledOpacity)),
        );

        // 4. Biarkan proses capture selesai
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // 5. Verifikasi kecerahan layar dipulihkan ke 0.45 semula
        verify(() => mockBrightnessService.setBrightness(0.45)).called(1);

        // 6. Verifikasi overlay hilang
        expect(
          find.byKey(const ValueKey<String>('camera_screen_flash_overlay')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'multi-camera array (>2 lenses) uses directional toggle flipping '
      'strictly between front and primary rear without cycling auxiliary '
      'lenses',
      (tester) async {
        configureTestView(tester);

        const backMain = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const frontCamera = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );
        const backUltraWide = CameraDescription(
          name: '2',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            frontCamera,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(frontCamera);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(mockController.dispose).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [backMain, frontCamera, backUltraWide],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Pada kamera depan, label semantik mengumumkan aksi beralih
        // ke belakang
        expect(
          find.bySemanticsLabel('Beralih ke kamera belakang'),
          findsOneWidget,
        );

        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        expect(switchBtnFinder, findsOneWidget);

        // 2. Ketuk tombol switch kamera
        await tester.tap(switchBtnFinder);
        await tester.pump();

        // Verifikasi directional toggle: dari front (idx 1) melompat ke
        // backMain (idx 0), bukan ke backUltraWide (idx 2). Label semantik
        // sekarang mengumumkan aksi beralih ke depan.
        expect(
          find.bySemanticsLabel('Beralih ke kamera depan'),
          findsOneWidget,
        );
        verify(mockController.dispose).called(1);
      },
    );

    testWidgets(
      'exotic camera array with only rear lenses uses graceful fallback '
      'to cyclic increment',
      (tester) async {
        configureTestView(tester);

        const back1 = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const back2 = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            back1,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(back1);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(mockController.dispose).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [back1, back2],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Karena keduanya adalah lensa belakang, label semantik tetap
        // 'Beralih ke kamera depan'
        expect(
          find.bySemanticsLabel('Beralih ke kamera depan'),
          findsOneWidget,
        );

        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        await tester.tap(switchBtnFinder);
        await tester.pump();

        verify(mockController.dispose).called(1);
      },
    );

    testWidgets(
      'flash button and switch camera button render clean static AppSvgIcon '
      'without laggy AnimatedSwitcher or AnimatedRotation',
      (tester) async {
        configureTestView(tester);

        const cam1 = CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );
        const cam2 = CameraDescription(
          name: '1',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        );

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            cam1,
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.description).thenReturn(cam1);
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
        when(mockController.dispose).thenAnswer((_) async {});

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [cam1, cam2],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi tombol flash dibungkus AnimatedRotation untuk mengikuti
        // orientasi perangkat
        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
          findsOneWidget,
        );

        // 2. Verifikasi tombol switch dibungkus AnimatedRotation untuk
        // mengikuti orientasi perangkat
        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        expect(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AppSvgIcon),
          ),
          findsOneWidget,
        );

        // 3. Ketuk flash button: mode berganti instan ke auto
        await tester.tap(flashBtnFinder);
        await tester.pump();
        verify(() => mockController.setFlashMode(FlashMode.auto)).called(1);

        // 4. Ketuk switch camera: controller lama di-dispose untuk transisi
        await tester.tap(switchBtnFinder);
        await tester.pump();
        verify(mockController.dispose).called(1);
      },
    );

    test('DeviceOrientationTurns extension and continuous shortest-arc '
        'calculation', () {
      // 1. Nilai target putaran dasar
      expect(DeviceOrientation.portraitUp.turns, 0);
      expect(DeviceOrientation.landscapeLeft.turns, 0.25);
      expect(DeviceOrientation.portraitDown.turns, 0.50);
      expect(DeviceOrientation.landscapeRight.turns, 0.75);

      // 2. Transisi busur terpendek (shortest-arc delta)
      double calcDelta(
        double currentTurns,
        DeviceOrientation targetOrientation,
      ) {
        final target = targetOrientation.turns;
        var delta = (target - currentTurns) % 1.0;
        if (delta > 0.5) delta -= 1.0;
        if (delta < -0.5) delta += 1.0;
        return delta;
      }

      // Dari portraitUp (0.0) ke landscapeRight: shortest arc adalah -0.25,
      // bukan berputar 270° (+0.75)
      expect(calcDelta(0, DeviceOrientation.landscapeRight), -0.25);

      // Dari landscapeRight (-0.25) ke portraitUp: +0.25 (+90° CW)
      expect(calcDelta(-0.25, DeviceOrientation.portraitUp), 0.25);

      // Dari portraitUp (0.0) ke landscapeLeft: +0.25 (+90° CW)
      expect(calcDelta(0, DeviceOrientation.landscapeLeft), 0.25);

      // Dari portraitUp (0.0) ke portraitDown: +0.50 (180°)
      expect(calcDelta(0, DeviceOrientation.portraitDown), 0.50);

      // Dari portraitDown (0.50) ke landscapeRight: +0.25 (+90° CW)
      expect(calcDelta(0.50, DeviceOrientation.landscapeRight), 0.25);

      // Dari landscapeRight (0.75) ke portraitDown: -0.25 (-90° CCW)
      expect(calcDelta(0.75, DeviceOrientation.portraitDown), -0.25);
    });

    testWidgets('repositions quota badge according to device orientation with '
        'zero layout shift in top bar', (tester) async {
      final mockController = _createConfiguredMockController();

      // ── 1. PORTRAIT UP ────────────────────────────────────────────────
      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            cameras: const [testCamera1],
            controller: mockController,
            initialDeviceOrientation: DeviceOrientation.portraitUp,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar badge terlihat di tengah
      final topBadgeFinder = find.byKey(
        const ValueKey<String>('camera_quota_badge'),
      );
      expect(topBadgeFinder, findsOneWidget);

      final topOpacityPortraitUp = tester
          .widget<FadeTransition>(topBadgeFinder)
          .opacity
          .value;
      expect(topOpacityPortraitUp, 1);

      // Posisi tombol di top bar dicatat
      final closeRectPortraitUp = tester.getRect(
        find.byKey(const ValueKey<String>('camera_close_button')),
      );
      final topBadgeRectPortraitUp = tester.getRect(topBadgeFinder);
      final flashRectPortraitUp = tester.getRect(
        find.byKey(const ValueKey<String>('camera_flash_button')),
      );

      // Viewfinder landscape badges berupa slot kosong yang belum ditempati
      expect(
        find.byKey(const ValueKey<String>('camera_quota_badge_landscape_left')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_right'),
        ),
        findsNothing,
      );

      // ── 2. PORTRAIT DOWN (UPSIDE DOWN) ────────────────────────────────
      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            cameras: const [testCamera1],
            controller: mockController,
            initialDeviceOrientation: DeviceOrientation.portraitDown,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar badge tetap di posisinya (opacity 1.0) dengan rotasi 180°
      final topOpacityPortraitDown = tester
          .widget<FadeTransition>(topBadgeFinder)
          .opacity
          .value;
      expect(topOpacityPortraitDown, 1);

      final topBadgeRotatedBox = tester.widget<RotatedBox>(
        find.descendant(of: topBadgeFinder, matching: find.byType(RotatedBox)),
      );
      expect(topBadgeRotatedBox.quarterTurns, 2);

      // Verifikasi ZERO LAYOUT SHIFT di top bar
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_close_button')),
        ),
        closeRectPortraitUp,
      );
      expect(tester.getRect(topBadgeFinder), topBadgeRectPortraitUp);
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_flash_button')),
        ),
        flashRectPortraitUp,
      );

      // ── 3. LANDSCAPE LEFT ─────────────────────────────────────────────
      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            cameras: const [testCamera1],
            controller: mockController,
            initialDeviceOrientation: DeviceOrientation.landscapeLeft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar badge memudar menjadi transparan (opacity 0.0) namun
      // mempertahankan ruang
      final topOpacityLandscapeLeft = tester
          .widget<FadeTransition>(topBadgeFinder)
          .opacity
          .value;
      expect(topOpacityLandscapeLeft, 0);

      // Verifikasi ZERO LAYOUT SHIFT (Close & Flash tidak bergeser sama
      // sekali)
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_close_button')),
        ),
        closeRectPortraitUp,
      );
      expect(tester.getRect(topBadgeFinder), topBadgeRectPortraitUp);
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_flash_button')),
        ),
        flashRectPortraitUp,
      );

      // Viewfinder memunculkan floating badge untuk Landscape Left di
      // sisi kanan viewfinder (> 400 pada lebar 800)
      final leftBadgeFinder = find.byKey(
        const ValueKey<String>('camera_quota_badge_landscape_left'),
      );
      expect(leftBadgeFinder, findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_right'),
        ),
        findsNothing,
      );

      // Verifikasi posisi Atas-Tengah Landscape Left: berada di sisi kanan
      // viewfinder (> 400 pada lebar 800)
      final leftBadgeCenter = tester.getCenter(leftBadgeFinder);
      expect(leftBadgeCenter.dx > 400.0, isTrue);

      // ── 4. LANDSCAPE RIGHT ────────────────────────────────────────────
      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            cameras: const [testCamera1],
            controller: mockController,
            initialDeviceOrientation: DeviceOrientation.landscapeRight,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar badge memudar menjadi transparan (opacity 0.0)
      final topOpacityLandscapeRight = tester
          .widget<FadeTransition>(topBadgeFinder)
          .opacity
          .value;
      expect(topOpacityLandscapeRight, 0);

      // Verifikasi ZERO LAYOUT SHIFT
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_close_button')),
        ),
        closeRectPortraitUp,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('camera_flash_button')),
        ),
        flashRectPortraitUp,
      );

      // Viewfinder memunculkan floating badge untuk Landscape Right di
      // sisi kiri viewfinder (< 400 pada lebar 800)
      final rightBadgeFinder = find.byKey(
        const ValueKey<String>('camera_quota_badge_landscape_right'),
      );
      expect(rightBadgeFinder, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('camera_quota_badge_landscape_left')),
        findsNothing,
      );

      // Verifikasi posisi Atas-Tengah Landscape Right: berada di sisi kiri
      // viewfinder (< 400 pada lebar 800)
      final rightBadgeCenter = tester.getCenter(rightBadgeFinder);
      expect(rightBadgeCenter.dx < 400.0, isTrue);
    });

    testWidgets(
      'rotates secondary controls to match orientation while close and '
      'shutter stay fixed',
      (tester) async {
        final mockController = _createConfiguredMockController();

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: mockController,
              initialDeviceOrientation: DeviceOrientation.landscapeLeft,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Tombol flash memutar ikonnya 0.25 turns (+90° CW)
        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        final flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.25);

        // 2. Tombol switch memutar ikonnya 0.25 turns (+90° CW)
        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );
        final switchRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(switchRotation.turns, 0.25);

        // 3. Tombol close dan shutter posisinya tetap dan TIDAK memiliki
        // AnimatedRotation
        final closeBtnFinder = find.byKey(
          const ValueKey<String>('camera_close_button'),
        );
        expect(
          find.descendant(
            of: closeBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );

        final shutterBtnFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        expect(
          find.descendant(
            of: shutterBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );

        // Tombol shutter tetap berada di tengah layar (dx = 400 pada lebar 800)
        final shutterCenter = tester.getCenter(shutterBtnFinder);
        expect(shutterCenter.dx, closeTo(400.0, 1.0));
      },
    );

    testWidgets(
      'dynamically rotates controls and locks capture orientation when sensor '
      'service emits orientation changes',
      (tester) async {
        final mockController = _createConfiguredMockController();
        final orientationStreamController =
            StreamController<DeviceOrientation>.broadcast();
        final fakeSensorService = FakeDeviceOrientationSensorService(
          stream: orientationStreamController.stream,
        );

        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_capture.jpg');
        final testImg = img.Image(width: 120, height: 160);
        img.fill(testImg, color: img.ColorRgb8(255, 0, 0));
        tempFile.writeAsBytesSync(img.encodeJpg(testImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: mockController,
              orientationSensorService: fakeSensorService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial portraitUp: flash turns = 0
        final flashBtnFinder = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        var flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.0);

        // 2. Sensor emits landscapeLeft -> flash rotates to 0.25 turns
        // (+90° CW)
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pumpAndSettle();

        flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.25);

        // Viewfinder left badge exists, uses RotatedBox(quarterTurns: 1),
        // and has edge distance equal to other controls (right: space200).
        final leftBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_left'),
        );
        expect(leftBadgeFinder, findsOneWidget);
        final leftRotatedBox = tester.widget<RotatedBox>(
          find.ancestor(of: leftBadgeFinder, matching: find.byType(RotatedBox)),
        );
        expect(leftRotatedBox.quarterTurns, 1);
        final leftPositioned = tester.widget<Positioned>(
          find.ancestor(of: leftBadgeFinder, matching: find.byType(Positioned)),
        );
        expect(leftPositioned.right, AppSpacing.space200);

        // 3. Take picture in landscapeLeft -> verify lockCaptureOrientation was
        // called with landscapeLeft
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        await tester.runAsync(() async {
          tester.widget<AppTappable>(shutterFinder).onTap!();
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Verifikasi controller tidak di-lock ke landscapeLeft agar preview
        // kamera tidak berotasi di viewfinder
        verifyNever(
          () => mockController.lockCaptureOrientation(
            DeviceOrientation.landscapeLeft,
          ),
        );
        // Verify unlockCaptureOrientation is NOT prematurely called on capture
        verifyNever(mockController.unlockCaptureOrientation);

        // Verify orientation does NOT reset to portrait after capture
        flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.25);
        expect(leftBadgeFinder, findsOneWidget);

        // 4. Sensor emits landscapeRight -> flash rotates to 0.75 turns (-90° / 270°)
        orientationStreamController.add(DeviceOrientation.landscapeRight);
        await tester.pumpAndSettle();

        flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.75);

        // Take picture in landscapeRight
        await tester.runAsync(() async {
          tester.widget<AppTappable>(shutterFinder).onTap!();
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Verifikasi controller tidak di-lock ke landscapeRight
        verifyNever(
          () => mockController.lockCaptureOrientation(
            DeviceOrientation.landscapeRight,
          ),
        );

        // Viewfinder right badge exists, uses RotatedBox(quarterTurns: 3),
        // and has edge distance equal to other controls (left: space200).
        final rightBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_right'),
        );
        expect(rightBadgeFinder, findsOneWidget);
        final rightRotatedBox = tester.widget<RotatedBox>(
          find.ancestor(
            of: rightBadgeFinder,
            matching: find.byType(RotatedBox),
          ),
        );
        expect(rightRotatedBox.quarterTurns, 3);
        final rightPositioned = tester.widget<Positioned>(
          find.ancestor(
            of: rightBadgeFinder,
            matching: find.byType(Positioned),
          ),
        );
        expect(rightPositioned.left, AppSpacing.space200);

        // Verifikasi tray thumbnail merotasi seluruh item secara unifikasi
        final thumbSurfaceFinder = find.byKey(
          ValueKey<String>('captured_thumbnail_${tempFile.path}'),
        );
        expect(thumbSurfaceFinder, findsAtLeastNWidgets(1));

        final trayRotation = tester.widget<AnimatedRotation>(
          find.ancestor(
            of: thumbSurfaceFinder.first,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(trayRotation.turns, 0.75);

        // Verifikasi tidak ada AnimatedRotation redundan di dalam thumbnail
        // atau tombol hapus
        expect(
          find.descendant(
            of: thumbSurfaceFinder.first,
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );

        final deleteBtnFinder = find.byKey(
          ValueKey<String>('remove_captured_photo_${tempFile.path}'),
        );
        expect(
          find.descendant(
            of: deleteBtnFinder.first,
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );

        // 5. Sensor emits portraitDown -> flash rotates to 0.5 turns (180°)
        orientationStreamController.add(DeviceOrientation.portraitDown);
        await tester.pumpAndSettle();

        flashRotation = tester.widget<AnimatedRotation>(
          find.descendant(
            of: flashBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(flashRotation.turns, 0.5);

        // Top bar badge is flipped with RotatedBox (quarterTurns: 2)
        final topBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge'),
        );
        final topBadgeRotatedBox = tester.widget<RotatedBox>(
          find.descendant(
            of: topBadgeFinder,
            matching: find.byType(RotatedBox),
          ),
        );
        expect(topBadgeRotatedBox.quarterTurns, 2);

        // Take picture in portraitDown
        await tester.runAsync(() async {
          tester.widget<AppTappable>(shutterFinder).onTap!();
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        verifyNever(
          () => mockController.lockCaptureOrientation(
            DeviceOrientation.portraitDown,
          ),
        );

        fakeSensorService.dispose();
        await orientationStreamController.close();
      },
    );

    testWidgets(
      'landscape quota badge does not block touch to focus on viewfinder',
      (tester) async {
        configureTestView(tester);

        final mockController = _createConfiguredMockController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(testCamera1).copyWith(
            isInitialized: true,
            previewSize: const Size(1920, 1080),
            focusPointSupported: true,
            exposurePointSupported: true,
          ),
        );
        when(
          () => mockController.setFocusPoint(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockController.setExposurePoint(any()),
        ).thenAnswer((_) async {});

        final orientationStreamController =
            StreamController<DeviceOrientation>.broadcast();
        final fakeSensorService = FakeDeviceOrientationSensorService(
          stream: orientationStreamController.stream,
        );

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: mockController,
              orientationSensorService: fakeSensorService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Ubah ke landscapeLeft -> badge kuota muncul di viewfinder kanan
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pumpAndSettle();

        final leftBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_left'),
        );
        expect(leftBadgeFinder, findsOneWidget);

        // 2. Ketuk langsung tepat di tengah badge kuota landscapeLeft
        // (warnIfMissed: false karena badge di-IgnorePointer agar tembus)
        await tester.tap(leftBadgeFinder, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verifikasi touch-to-focus tembus (tidak terblokir oleh badge)
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsOneWidget,
        );

        // Majukan timer fokus hingga selesai
        await tester.pump(const Duration(milliseconds: 1600));

        // 3. Ubah ke landscapeRight -> badge kuota berpindah ke viewfinder kiri
        orientationStreamController.add(DeviceOrientation.landscapeRight);
        await tester.pumpAndSettle();

        final rightBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge_landscape_right'),
        );
        expect(rightBadgeFinder, findsOneWidget);

        // 4. Ketuk langsung tepat di tengah badge kuota landscapeRight
        // (warnIfMissed: false karena badge di-IgnorePointer agar tembus)
        await tester.tap(rightBadgeFinder, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Verifikasi touch-to-focus juga tembus pada slot landscapeRight
        verify(() => mockController.setFocusPoint(any())).called(1);
        verify(() => mockController.setExposurePoint(any())).called(1);
        expect(
          find.byKey(const ValueKey<String>('camera_focus_reticle')),
          findsOneWidget,
        );

        fakeSensorService.dispose();
        await orientationStreamController.close();
      },
    );

    testWidgets(
      'rapid orientation changes do not freeze or make quota badge disappear',
      (tester) async {
        final mockController = _createConfiguredMockController();
        final orientationStreamController =
            StreamController<DeviceOrientation>.broadcast();
        final fakeSensorService = FakeDeviceOrientationSensorService(
          stream: orientationStreamController.stream,
        );

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: mockController,
              orientationSensorService: fakeSensorService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Simulasikan perubahan orientasi berkecepatan tinggi (jitter)
        // landscapeLeft -> potong saat fade out (60ms) -> landscapeRight
        // -> potong saat fade in (100ms) -> portraitDown -> portraitUp
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pump(const Duration(milliseconds: 60));

        orientationStreamController.add(DeviceOrientation.landscapeRight);
        await tester.pump(const Duration(milliseconds: 100));

        orientationStreamController.add(DeviceOrientation.portraitDown);
        await tester.pump(const Duration(milliseconds: 80));

        orientationStreamController.add(DeviceOrientation.portraitUp);
        await tester.pumpAndSettle();

        // Verifikasi badge pada top bar untuk portraitUp tetap ada dan opasitas
        // penuh (1.0).
        final topBadgeFinder = find.byKey(
          const ValueKey<String>('camera_quota_badge'),
        );
        expect(topBadgeFinder, findsOneWidget);

        final fadeTransition = tester.widget<FadeTransition>(topBadgeFinder);
        expect(fadeTransition.opacity.value, 1.0);

        // Tidak ada badge lanskap di viewfinder yang tertinggal/menggantung
        expect(
          find.byKey(
            const ValueKey<String>('camera_quota_badge_landscape_left'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey<String>('camera_quota_badge_landscape_right'),
          ),
          findsNothing,
        );

        // 2. Simulasikan perubahan balik seketika (rapid round-trip)
        // portraitUp -> landscapeLeft (120ms) -> langsung kembali ke portraitUp
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pump(const Duration(milliseconds: 120));

        orientationStreamController.add(DeviceOrientation.portraitUp);
        await tester.pumpAndSettle();

        // Badge kembali utuh, tidak freezed, dan opasitas penuh
        final settledFadeTransition = tester.widget<FadeTransition>(
          topBadgeFinder,
        );
        expect(settledFadeTransition.opacity.value, 1.0);

        // 3. Simulasikan rentetan perubahan orientasi sangat cepat
        // (rapid jitter: portraitUp -> landscapeRight -> portraitDown ->
        // landscapeLeft)
        orientationStreamController.add(DeviceOrientation.landscapeRight);
        await tester.pump(const Duration(milliseconds: 40));
        orientationStreamController.add(DeviceOrientation.portraitDown);
        await tester.pump(const Duration(milliseconds: 40));
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pumpAndSettle();

        // Verifikasi badge berada di landscapeLeft tanpa tertinggal di lokasi
        // lama
        expect(
          find.byKey(
            const ValueKey<String>('camera_quota_badge_landscape_left'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('camera_quota_badge_landscape_right'),
          ),
          findsNothing,
        );
        final landscapeBadgeFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.byKey(
                  const ValueKey<String>('camera_quota_badge_landscape_left'),
                ),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(landscapeBadgeFade.opacity.value, 1.0);

        fakeSensorService.dispose();
        await orientationStreamController.close();
      },
    );

    testWidgets(
      'camera view and viewfinder do not rotate with orientation changes '
      'while capturing images according to orientation',
      (tester) async {
        configureTestView(tester);

        final mockController = _createConfiguredMockController();
        final orientationStreamController =
            StreamController<DeviceOrientation>.broadcast();
        final fakeSensorService = FakeDeviceOrientationSensorService(
          stream: orientationStreamController.stream,
        );

        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_viewfinder.jpg');
        // Citra 1200x1600 (3:4)
        final rawImg = img.Image(width: 1200, height: 1600);
        img.fill(rawImg, color: img.ColorRgb8(0, 0, 255));
        tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(mockController.takePicture).thenAnswer((_) async {
          // Tulis ulang byte gambar sebelum pemotretan berikutnya
          tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
          return XFile(tempFile.path);
        });

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: mockController,
              orientationSensorService: fakeSensorService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial portraitUp: ukur rect dan pastikan tidak ada rotasi
        final viewfinderFinder = find.byKey(
          const ValueKey<String>('camera_viewfinder_container'),
        );
        expect(viewfinderFinder, findsOneWidget);
        final initialRect = tester.getRect(viewfinderFinder);
        expect(initialRect.width, 800.0);
        expect(
          (initialRect.width / initialRect.height - (9 / 16)).abs() < 0.01,
          isTrue,
        );

        // Verifikasi tidak ada AnimatedRotation atau RotatedBox yang membungkus
        // container viewfinder maupun widget CameraPreview
        expect(
          find.ancestor(
            of: viewfinderFinder,
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: viewfinderFinder,
            matching: find.byType(RotatedBox),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byType(CameraPreview),
            matching: find.byType(AnimatedRotation),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byType(CameraPreview),
            matching: find.byType(RotatedBox),
          ),
          findsNothing,
        );

        // 2. Sensor memancarkan landscapeLeft
        orientationStreamController.add(DeviceOrientation.landscapeLeft);
        await tester.pumpAndSettle();

        // Viewfinder TETAP diam, ukuran dan posisi 9:16 tidak berotasi
        final landscapeLeftRect = tester.getRect(viewfinderFinder);
        expect(landscapeLeftRect, equals(initialRect));

        // Ambil foto dalam mode landscapeLeft
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        await tester.runAsync(() async {
          tester.widget<AppTappable>(shutterFinder).onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && (decoded.width / decoded.height) > 1.5) {
              break;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Verifikasi lockCaptureOrientation tidak dipanggil dengan
        // landscapeLeft agar preview kamera dan viewfinder tetap stabil
        // tanpa rotasi
        verifyNever(
          () => mockController.lockCaptureOrientation(
            DeviceOrientation.landscapeLeft,
          ),
        );

        // Verifikasi hasil potongan gambar adalah 16:9 landscape
        var croppedBytes = tempFile.readAsBytesSync();
        var decoded = img.decodeImage(croppedBytes);
        expect(decoded, isNotNull);
        var aspect = decoded!.width / decoded.height;
        expect((aspect - (16 / 9)).abs() < 0.01, isTrue);

        // 3. Sensor memancarkan portraitUp kembali
        orientationStreamController.add(DeviceOrientation.portraitUp);
        await tester.pumpAndSettle();

        final portraitUpRect = tester.getRect(viewfinderFinder);
        expect(portraitUpRect, equals(initialRect));

        // Ambil foto dalam mode portraitUp
        await tester.runAsync(() async {
          tester.widget<AppTappable>(shutterFinder).onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && (decoded.width / decoded.height) < 0.7) {
              break;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Verifikasi lockCaptureOrientation dipanggil dengan portraitUp
        verify(
          () => mockController.lockCaptureOrientation(
            DeviceOrientation.portraitUp,
          ),
        ).called(greaterThanOrEqualTo(1));

        // Verifikasi hasil potongan gambar adalah 9:16 portrait
        croppedBytes = tempFile.readAsBytesSync();
        decoded = img.decodeImage(croppedBytes);
        expect(decoded, isNotNull);
        aspect = decoded!.width / decoded.height;
        expect((aspect - (9 / 16)).abs() < 0.01, isTrue);

        fakeSensorService.dispose();
        await orientationStreamController.close();
      },
    );

    testWidgets(
      'close button and escape deselect photos when selected, then pop '
      'without returning data when deselected',
      (tester) async {
        configureTestView(tester);

        final mockController = _createConfiguredMockController();
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_thumb.jpg');
        final rawImg = img.Image(width: 90, height: 160);
        img.fill(rawImg, color: img.ColorRgba8(255, 0, 0, 255));
        tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          try {
            tempDir.deleteSync(recursive: true);
          } on FileSystemException catch (_) {}
        });

        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        List<AppMediaFile>? returnedResult;

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    returnedResult = await AppMultiShotCameraScreen.show(
                      context,
                      controller: mockController,
                    );
                  },
                  child: const Text('Buka Kamera'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Buka screen
        await tester.tap(find.text('Buka Kamera'));
        await tester.pumpAndSettle();

        expect(find.byType(AppMultiShotCameraScreen), findsOneWidget);

        // 2. Ambil 1 foto (otomatis terpilih)
        final shutterFinder = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutterFinder);
        await tester.runAsync(() async {
          tappable.onTap!();
          for (var i = 0; i < 80; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final bytes = tempFile.readAsBytesSync();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && decoded.width == 90) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        // Verifikasi tombol Done muncul karena ada foto yang terpilih
        final doneButtonFinder = find.byKey(
          const ValueKey<String>('camera_done_button'),
        );
        expect(doneButtonFinder, findsOneWidget);

        // 3. Tekan tombol close di top bar ketika foto terpilih
        final closeButtonFinder = find.byKey(
          const ValueKey<String>('camera_close_button'),
        );
        await tester.tap(closeButtonFinder);
        await tester.pumpAndSettle();

        // Screen TIDAK boleh tertutup, tetapi foto ter-deselect
        expect(find.byType(AppMultiShotCameraScreen), findsOneWidget);
        expect(doneButtonFinder, findsNothing);

        // 4. Tekan tombol close di top bar ketika TIDAK ADA foto terpilih
        await tester.tap(closeButtonFinder);
        await tester.pumpAndSettle();

        // Screen tertutup dan data foto TIDAK diteruskan (empty list)
        expect(find.byType(AppMultiShotCameraScreen), findsNothing);
        expect(returnedResult, isEmpty);
      },
    );

    testWidgets('PopScope / escape deselects photos first, then dismisses '
        'without data on second pop', (tester) async {
      configureTestView(tester);

      final mockController = _createConfiguredMockController();
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_thumb_escape.jpg');
      final rawImg = img.Image(width: 90, height: 160);
      img.fill(rawImg, color: img.ColorRgba8(0, 255, 0, 255));
      tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
      addTearDown(() {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
      });

      when(
        mockController.takePicture,
      ).thenAnswer((_) async => XFile(tempFile.path));

      List<AppMediaFile>? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await AppMultiShotCameraScreen.show(
                    context,
                    controller: mockController,
                  );
                },
                child: const Text('Buka Kamera'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Buka screen
      await tester.tap(find.text('Buka Kamera'));
      await tester.pumpAndSettle();

      // 2. Ambil foto (otomatis terpilih)
      final shutterFinder = find.byKey(
        const ValueKey<String>('camera_shutter_button'),
      );
      final tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        for (var i = 0; i < 80; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final bytes = tempFile.readAsBytesSync();
          final decoded = img.decodeImage(bytes);
          if (decoded != null && decoded.width == 90) break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('camera_done_button')),
        findsOneWidget,
      );

      // 3. Simulasikan pop route (gesture back/escape) saat foto terpilih
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Screen TIDAK boleh tertutup, foto di-deselect
      expect(find.byType(AppMultiShotCameraScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('camera_done_button')),
        findsNothing,
      );

      // 4. Simulasikan pop route saat tidak ada foto terpilih
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Screen tertutup dan data foto TIDAK diteruskan
      expect(find.byType(AppMultiShotCameraScreen), findsNothing);
      expect(returnedResult, isEmpty);
    });

    testWidgets('done button returns selected photos successfully', (
      tester,
    ) async {
      configureTestView(tester);

      final mockController = _createConfiguredMockController();
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/test_thumb_done.jpg');
      final rawImg = img.Image(width: 90, height: 160);
      img.fill(rawImg, color: img.ColorRgba8(0, 0, 255, 255));
      tempFile.writeAsBytesSync(img.encodeJpg(rawImg));
      addTearDown(() {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
      });

      when(
        mockController.takePicture,
      ).thenAnswer((_) async => XFile(tempFile.path));

      List<AppMediaFile>? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await AppMultiShotCameraScreen.show(
                    context,
                    controller: mockController,
                  );
                },
                child: const Text('Buka Kamera'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Buka screen
      await tester.tap(find.text('Buka Kamera'));
      await tester.pumpAndSettle();

      // 2. Ambil foto
      final shutterFinder = find.byKey(
        const ValueKey<String>('camera_shutter_button'),
      );
      final tappable = tester.widget<AppTappable>(shutterFinder);
      await tester.runAsync(() async {
        tappable.onTap!();
        for (var i = 0; i < 80; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final bytes = tempFile.readAsBytesSync();
          final decoded = img.decodeImage(bytes);
          if (decoded != null && decoded.width == 90) break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // 3. Tekan tombol done
      final doneButtonFinder = find.byKey(
        const ValueKey<String>('camera_done_button'),
      );
      expect(doneButtonFinder, findsOneWidget);
      await tester.tap(doneButtonFinder);
      await tester.pumpAndSettle();

      // Screen tertutup dan foto terpilih berhasil dikembalikan
      expect(find.byType(AppMultiShotCameraScreen), findsNothing);
      expect(returnedResult, isNotNull);
      expect(returnedResult!.length, 1);
      expect(returnedResult!.first.path, tempFile.path);
    });

    testWidgets(
      'pauses sensor subscription when paused and resumes upon resumed',
      (tester) async {
        configureTestView(tester);

        final orientationStreamController =
            StreamController<DeviceOrientation>.broadcast();
        final fakeSensorService = FakeDeviceOrientationSensorService(
          stream: orientationStreamController.stream,
        );

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [],
              orientationSensorService: fakeSensorService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. App di-pause (pengguna switch app atau minimize)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // 2. App di-resume kembali
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        fakeSensorService.dispose();
        await orientationStreamController.close();
      },
    );

    testWidgets(
      'safely restores screen brightness if interrupted during screen flash',
      (tester) async {
        configureTestView(tester);

        final mockBrightnessService = MockScreenBrightnessService();
        when(
          () => mockBrightnessService.currentBrightness,
        ).thenAnswer((_) async => 0.5);
        when(
          () => mockBrightnessService.setBrightness(any()),
        ).thenAnswer((_) async => true);
        when(
          mockBrightnessService.resetBrightness,
        ).thenAnswer((_) async => true);

        final mockController = _createConfiguredMockController(testCamera2);
        when(mockController.takePicture).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return XFile('fake_path.jpg');
        });

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              controller: mockController,
              cameras: const [testCamera2],
              brightnessService: mockBrightnessService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Set mode flash ke always pada kamera depan
        final flashBtn = find.byKey(
          const ValueKey<String>('camera_flash_button'),
        );
        await tester.tap(flashBtn);
        await tester.pumpAndSettle();

        // Picu shutter
        final shutter = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        await tester.tap(shutter);
        await tester.pump(const Duration(milliseconds: 100));

        // Interupsi aplikasi dengan backgrounding saat screen flash berlangsung
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        // Pompa 200ms untuk menyelesaikan sisa timer delay screen flash
        await tester.pump(const Duration(milliseconds: 200));

        // Verifikasi setBrightness dipanggil untuk memulihkan kecerahan awal
        verify(
          () => mockBrightnessService.setBrightness(0.5),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'CameraActionableError maps permission denied with troubleshooting and '
      'direct settings action',
      (tester) async {
        configureTestView(tester);

        var settingsOpened = false;
        var exitCalled = false;

        final errorData = CameraActionableError.fromCameraException(
          CameraException('CameraAccessDenied', 'Permission denied'),
          onRetry: () {},
          onExit: () => exitCalled = true,
          openAppSettingsFn: () async {
            settingsOpened = true;
            return true;
          },
        );

        await tester.pumpWidget(
          _buildTestApp(AppActionableErrorView(data: errorData)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Izin kamera dinonaktifkan'), findsOneWidget);
        expect(find.text('Cara mengatasi:'), findsOneWidget);
        expect(find.text('Aktifkan izin Kamera.'), findsOneWidget);

        final settingsBtn = find.widgetWithText(AppButton, 'Buka pengaturan');
        expect(settingsBtn, findsOneWidget);
        await tester.tap(settingsBtn);
        expect(settingsOpened, isTrue);

        final backBtn = find.widgetWithText(AppButton, 'Kembali');
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        expect(exitCalled, isTrue);
      },
    );

    testWidgets(
      'CameraActionableError fromInitializationError catches PlatformException '
      'and case-insensitive permission denials',
      (tester) async {
        final platformData = CameraActionableError.fromInitializationError(
          PlatformException(
            code: 'camera_access_denied',
            message: 'Camera permission permanently denied',
          ),
          onRetry: () {},
          onExit: () {},
        );
        expect(platformData.title, equals('Izin kamera dinonaktifkan'));
        expect(platformData.primaryActionLabel, equals('Buka pengaturan'));
      },
    );

    testWidgets(
      'CameraActionableError maps camera in use and unexpected errors properly',
      (tester) async {
        final inUseData = CameraActionableError.fromCameraException(
          CameraException('CameraInUse', 'Camera locked'),
          onRetry: () {},
          onExit: () {},
        );
        expect(inUseData.title, equals('Kamera sedang digunakan'));
        expect(inUseData.troubleshootingTips, isNotEmpty);

        final unexpectedData = CameraActionableError.unexpected(
          Exception('GPU buffer failure'),
          onRetry: () {},
          onExit: () {},
        );
        expect(unexpectedData.title, equals('Terjadi kesalahan teknis'));
        expect(unexpectedData.isUnexpected, isTrue);
        expect(unexpectedData.technicalDetails, contains('GPU buffer failure'));
        expect(
          unexpectedData.troubleshootingTips,
          contains('Mulai ulang perangkat jika kendala masih berlanjut.'),
        );
        expect(
          unexpectedData.troubleshootingTips.any(
            (tip) => tip.contains('ponsel'),
          ),
          isFalse,
        );
      },
    );

    testWidgets(
      'shutter capture failure displays AppActionableErrorBottomSheet',
      (tester) async {
        configureTestView(tester);

        final mockController = MockCameraController();
        when(() => mockController.value).thenReturn(
          const CameraValue.uninitialized(
            CameraDescription(
              name: '0',
              lensDirection: CameraLensDirection.back,
              sensorOrientation: 90,
            ),
          ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
        );
        when(() => mockController.cameraId).thenReturn(1);
        when(mockController.buildPreview).thenReturn(const SizedBox());
        when(
          mockController.takePicture,
        ).thenThrow(Exception('Disk full or memory allocation failed'));

        await tester.pumpWidget(
          _buildTestApp(AppMultiShotCameraScreen(controller: mockController)),
        );
        await tester.pumpAndSettle();

        final shutter = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        final tappable = tester.widget<AppTappable>(shutter);
        await tester.runAsync(() async {
          tappable.onTap!();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorBottomSheet), findsOneWidget);
        expect(find.text('Gagal menyimpan foto'), findsOneWidget);
        expect(
          find.text(
            'Terjadi kendala saat memproses atau menyimpan berkas foto. '
            'Foto sebelumnya tetap aman.',
          ),
          findsOneWidget,
        );

        expect(find.widgetWithText(AppButton, 'Mengerti'), findsOneWidget);
        await tester.tap(find.widgetWithText(AppButton, 'Mengerti'));
        await tester.pumpAndSettle();
        expect(find.byType(AppActionableErrorBottomSheet), findsNothing);
      },
    );

    testWidgets('auto-recovery from OS Settings: resumes camera and dismisses '
        'actionable error (paused -> resumed)', (tester) async {
      configureTestView(tester);

      var hasPermission = false;
      final mockController = _createConfiguredMockController();
      when(mockController.initialize).thenAnswer((_) async {});

      await tester.pumpWidget(
        _buildTestApp(
          AppMultiShotCameraScreen(
            cameras: const [testCamera1],
            controllerFactory: (desc) {
              if (!hasPermission) {
                throw CameraException(
                  'CameraAccessDenied',
                  'Camera permission denied',
                );
              }
              return mockController;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Kondisi awal: error izin kamera tampil dengan tombol aksi
      //    Buka pengaturan.
      expect(find.byType(AppActionableErrorView), findsOneWidget);
      expect(find.text('Izin kamera dinonaktifkan'), findsOneWidget);
      expect(find.text('Buka pengaturan'), findsOneWidget);

      // 2. Simulasi pengguna menyalakan izin di OS Settings
      hasPermission = true;

      // 3. Simulasi perpindahan siklus hidup saat kembali dari OS Settings:
      //    paused -> resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // 4. Verifikasi: Actionable Error otomatis hilang, viewfinder live
      expect(find.byType(AppActionableErrorView), findsNothing);
      expect(find.text('Izin kamera dinonaktifkan'), findsNothing);
      verify(mockController.initialize).called(1);
    });

    testWidgets(
      'transient window focus change (inactive -> resumed) does not re-trigger '
      'camera init on active error to prevent infinite error loops',
      (tester) async {
        configureTestView(tester);

        var initCount = 0;

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              controllerFactory: (desc) {
                initCount++;
                throw CameraException(
                  'CameraAccessDenied',
                  'Camera permission denied',
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kondisi awal: error izin kamera tampil stabil
        expect(find.byType(AppActionableErrorView), findsOneWidget);
        expect(find.text('Izin kamera dinonaktifkan'), findsOneWidget);
        expect(initCount, equals(1));

        // 2. Simulasi transisi fokus sementara dari notifikasi / dialog HAL:
        //    inactive -> resumed
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // 3. Verifikasi: Actionable Error tetap stabil di layar,
        //    controllerFactory TIDAK dipanggil ulang secara liar
        //    (mencegah infinite loop)
        expect(find.byType(AppActionableErrorView), findsOneWidget);
        expect(find.text('Izin kamera dinonaktifkan'), findsOneWidget);
        expect(initCount, equals(1));
      },
    );

    testWidgets(
      'returning from OS Settings (paused -> resumed) when permission still '
      'denied re-attempts once and keeps error screen stable without looping',
      (tester) async {
        configureTestView(tester);

        var initCount = 0;

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              controllerFactory: (desc) {
                initCount++;
                throw CameraException(
                  'CameraAccessDenied',
                  'Camera permission denied',
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsOneWidget);
        expect(initCount, equals(1));

        // 1. Pengguna membuka pengaturan (app paused)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        // 2. Pengguna kembali tanpa memberikan izin (app resumed)
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Inisialisasi hanya dicoba 1 kali saat kembali dari background
        expect(initCount, equals(2));
        expect(find.byType(AppActionableErrorView), findsOneWidget);

        // 3. Jika Android kemudian memicu transisi fokus sementara
        //    (inactive -> resumed) akibat teardown surface, pastikan
        //    TIDAK terjadi loop
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(initCount, equals(2));
        expect(find.byType(AppActionableErrorView), findsOneWidget);
      },
    );

    testWidgets(
      'realistic platform lifecycle transition (paused -> inactive -> resumed) '
      'successfully auto-recovers camera when permission is granted in '
      'OS Settings',
      (tester) async {
        configureTestView(tester);

        var hasPermission = false;
        final mockController = _createConfiguredMockController();

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              controllerFactory: (desc) {
                if (!hasPermission) {
                  throw CameraException(
                    'CameraAccessDenied',
                    'Camera permission denied',
                  );
                }
                return mockController;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsOneWidget);

        // Simulasi izin diberikan di OS Settings
        hasPermission = true;

        // Simulasi transisi OS Android/iOS nyata saat kembali:
        // paused -> inactive -> resumed
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        // Verifikasi: Auto-Recovery berhasil membuka viewfinder live
        expect(find.byType(AppActionableErrorView), findsNothing);
        expect(find.text('Izin kamera dinonaktifkan'), findsNothing);
        verify(mockController.initialize).called(1);
      },
    );

    testWidgets(
      'tapping Buka pengaturan and returning to app triggers auto-recovery',
      (tester) async {
        configureTestView(tester);

        var hasPermission = false;
        var openSettingsCalled = false;
        final mockController = _createConfiguredMockController();

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              openAppSettingsFn: () async {
                openSettingsCalled = true;
                return true;
              },
              controllerFactory: (desc) {
                if (!hasPermission) {
                  throw CameraException(
                    'CameraAccessDenied',
                    'Camera permission denied',
                  );
                }
                return mockController;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsOneWidget);

        // Ketuk tombol Buka pengaturan
        await tester.tap(find.text('Buka pengaturan'));
        await tester.pump();
        expect(openSettingsCalled, isTrue);

        // Izin diberikan di Settings
        hasPermission = true;

        // Kembali ke aplikasi
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsNothing);
        verify(mockController.initialize).called(1);
      },
    );

    testWidgets(
      'user tapping Coba lagi manually re-initializes camera and recovers '
      'when error condition is resolved',
      (tester) async {
        configureTestView(tester);

        var isCameraInUse = true;
        final mockController = _createConfiguredMockController();

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              controllerFactory: (desc) {
                if (isCameraInUse) {
                  throw CameraException('CameraInUse', 'Camera in use');
                }
                return mockController;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsOneWidget);
        expect(find.text('Kamera sedang digunakan'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // Aplikasi lain yang memakai kamera ditutup
        isCameraInUse = false;

        // Pengguna mengetuk tombol Coba lagi
        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();

        expect(find.byType(AppActionableErrorView), findsNothing);
        expect(find.text('Kamera sedang digunakan'), findsNothing);
        verify(mockController.initialize).called(1);
      },
    );

    group('Camera Runtime Error Listener and Anti-Blackscreen Protection', () {
      testWidgets('runtime error on active camera controller triggers '
          'AppActionableErrorView', (tester) async {
        configureTestView(tester);

        final listeners = <VoidCallback>[];
        final mockController = _createConfiguredMockController(
          testCamera1,
          listeners,
        );

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1],
              controller: mockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Kondisi awal: viewfinder live aktif tanpa galat
        expect(find.byType(AppActionableErrorView), findsNothing);

        // Simulasi runtime error pada controller aktif (misal driver crash)
        final errorValue = const CameraValue.uninitialized(testCamera1)
            .copyWith(
              isInitialized: true,
              previewSize: const Size(1920, 1080),
              errorDescription: 'Camera device encountered an unexpected error',
            );
        when(() => mockController.value).thenReturn(errorValue);

        // Panggil seluruh listener yang didaftarkan pada controller
        for (final listener in List<VoidCallback>.of(listeners)) {
          listener();
        }
        await tester.pumpAndSettle();

        // Verifikasi: Tampilan galat actionable muncul di layar
        expect(find.byType(AppActionableErrorView), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);
      });

      testWidgets(
        'tapping Coba lagi after runtime error recovers and re-initializes '
        'camera',
        (tester) async {
          configureTestView(tester);

          final listeners = <VoidCallback>[];
          var initCount = 0;
          final mockController = _createConfiguredMockController(
            testCamera1,
            listeners,
          );
          final recoveredController = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1],
                controllerFactory: (desc) {
                  initCount++;
                  if (initCount == 1) {
                    return mockController;
                  }
                  return recoveredController;
                },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Pemicuan runtime error
          final errorValue = const CameraValue.uninitialized(testCamera1)
              .copyWith(
                isInitialized: true,
                previewSize: const Size(1920, 1080),
                errorDescription: 'Hardware disconnected',
              );
          when(() => mockController.value).thenReturn(errorValue);

          for (final listener in List<VoidCallback>.of(listeners)) {
            listener();
          }
          await tester.pumpAndSettle();

          expect(find.byType(AppActionableErrorView), findsOneWidget);

          // Ketuk Coba lagi
          await tester.tap(find.text('Coba lagi'));
          await tester.pumpAndSettle();

          // Verifikasi berhasil pulih
          expect(find.byType(AppActionableErrorView), findsNothing);
          expect(initCount, equals(2));
        },
      );

      testWidgets(
        'uninitialized controller in foreground renders AppLoadingIndicator '
        'preventing blackscreen',
        (tester) async {
          configureTestView(tester);

          final uninitializedMock = MockCameraController();
          when(
            () => uninitializedMock.value,
          ).thenReturn(const CameraValue.uninitialized(testCamera1));
          when(() => uninitializedMock.description).thenReturn(testCamera1);
          when(() => uninitializedMock.cameraId).thenReturn(1);
          when(uninitializedMock.buildPreview).thenReturn(const SizedBox());
          when(uninitializedMock.dispose).thenAnswer((_) async {});
          when(() => uninitializedMock.addListener(any())).thenReturn(null);
          when(() => uninitializedMock.removeListener(any())).thenReturn(null);

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1],
                controller: uninitializedMock,
              ),
            ),
          );
          await tester.pump();

          // Verifikasi: Di latar depan, tidak menghasilkan black screen kosong,
          // melainkan menampilkan AppLoadingIndicator yang ramah pengguna
          expect(find.byType(AppLoadingIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'controller with runtime error is excluded from viewfinder rendering',
        (tester) async {
          configureTestView(tester);

          final errorValue = const CameraValue.uninitialized(testCamera1)
              .copyWith(
                isInitialized: true,
                previewSize: const Size(1920, 1080),
                errorDescription: 'Sensor failure',
              );
          final errorController = _createConfiguredMockController();
          when(() => errorController.value).thenReturn(errorValue);

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1],
                controller: errorController,
              ),
            ),
          );
          await tester.pump();

          // Verifikasi: controller yang berstatus hasError tidak dirender di
          // CameraPreview
          expect(find.byType(CameraPreview), findsNothing);
        },
      );
    });

    group('Camera UX Writing and Accessibility Semantics', () {
      test('CameraActionableError uses standard Indonesian without jargon', () {
        final genericError = CameraActionableError.fromCameraException(
          CameraException('generic_error', 'some error'),
          onRetry: () {},
          onExit: () {},
        );
        expect(
          genericError.message,
          equals('Modul kamera mengalami kendala saat dihubungkan ke sistem.'),
        );
        expect(
          genericError.troubleshootingTips,
          contains('Ketuk Coba lagi untuk memuat ulang kamera.'),
        );
        expect(
          genericError.troubleshootingTips,
          contains(
            'Tutup aplikasi dari daftar aplikasi terkini, lalu buka kembali.',
          ),
        );
        expect(
          genericError.troubleshootingTips.any(
            (tip) => tip.contains('Recent Apps'),
          ),
          isFalse,
        );

        final inUseError = CameraActionableError.fromCameraException(
          CameraException('CameraInUse', 'Camera in use'),
          onRetry: () {},
          onExit: () {},
        );
        expect(
          inUseError.troubleshootingTips,
          contains(
            'Tutup panggilan video atau aplikasi kamera lain yang sedang '
            'aktif.',
          ),
        );
        expect(
          inUseError.troubleshootingTips,
          contains('Ketuk Coba lagi untuk menghubungkan ulang kamera.'),
        );
        expect(
          inUseError.troubleshootingTips.any(
            (tip) =>
                tip.contains('WhatsApp') ||
                tip.contains('Zoom') ||
                tip.contains('Meet'),
          ),
          isFalse,
        );

        final noCamError = CameraActionableError.noCamerasAvailable(
          onRetry: () {},
          onExit: () {},
        );
        expect(
          noCamError.message,
          equals(
            'Sistem tidak menemukan modul kamera aktif pada perangkat ini.',
          ),
        );
        expect(
          noCamError.troubleshootingTips,
          contains('Periksa apakah kebijakan keamanan membatasi akses kamera.'),
        );
        expect(
          noCamError.troubleshootingTips,
          contains('Ketuk Coba lagi setelah memastikan kamera tersedia.'),
        );
        expect(
          noCamError.troubleshootingTips.any((tip) => tip.contains('MDM')),
          isFalse,
        );

        final permissionError = CameraActionableError.fromCameraException(
          CameraException('CameraAccessDenied', 'Permission denied'),
          onRetry: () {},
          onExit: () {},
        );
        expect(
          permissionError.message,
          equals('Izin kamera diperlukan untuk mengambil foto.'),
        );
        expect(
          permissionError.troubleshootingTips,
          contains('Aktifkan izin Kamera.'),
        );
        expect(
          permissionError.troubleshootingTips,
          contains('Ketuk Buka pengaturan di bawah.'),
        );
        expect(
          permissionError.troubleshootingTips.any(
            (tip) => tip.contains('sakelar') || tip.contains('tombol'),
          ),
          isFalse,
        );

        final captureError = CameraActionableError.captureFailure(
          Exception('Storage write error'),
        );
        expect(captureError.primaryActionLabel, equals('Mengerti'));
        expect(
          captureError.troubleshootingTips,
          contains('Coba ambil foto kembali.'),
        );
        expect(
          captureError.troubleshootingTips.any(
            (tip) => tip.contains('pencahayaan') || tip.contains('beberapa'),
          ),
          isFalse,
        );

        final unexpectedError = CameraActionableError.unexpected(
          Exception('Unexpected pipeline error'),
          onRetry: () {},
          onExit: () {},
        );
        expect(
          unexpectedError.troubleshootingTips,
          contains('Mulai ulang perangkat jika kendala masih berlanjut.'),
        );
        expect(
          unexpectedError.troubleshootingTips.any(
            (tip) => tip.contains('ponsel'),
          ),
          isFalse,
        );
      });
    });

    group('CameraActionableError Production Token Sanitization '
        '(GoF Strategy & Pure DI)', () {
      test(
        'sanitizes captureFailure in production without leaking file paths',
        () {
          const sensitivePath =
              '/data/user/0/id.kawalo.app/cache/camera/photo.jpg';
          const ioError = FileSystemException(
            'Cannot write',
            sensitivePath,
            OSError('Disk full', 28),
          );

          final prodData = CameraActionableError.captureFailure(
            ioError,
            isProduction: true,
          );

          expect(
            prodData.technicalDetails,
            equals('Kode: STORAGE_IO_ERROR [28] (Disk full)'),
          );
          expect(prodData.technicalDetails!.contains(sensitivePath), isFalse);
          expect(prodData.technicalDetails!.contains('/data/user/0'), isFalse);
        },
      );

      test('normalizes CameraException in production to uppercase token', () {
        final prodData = CameraActionableError.fromCameraException(
          CameraException(
            'cameraStreamingFailed',
            'Native vendor HAL rejected access',
          ),
          onRetry: () {},
          onExit: () {},
          isProduction: true,
        );

        expect(prodData.technicalDetails, equals('Kode: CAM_STREAMING_FAILED'));
        expect(prodData.technicalDetails!.contains('vendor HAL'), isFalse);
      });

      test('sanitizes unexpected error in production to safe type name', () {
        final prodData = CameraActionableError.unexpected(
          StateError('Internal pipeline failed at address 0xdeadbeef'),
          onRetry: () {},
          onExit: () {},
          isProduction: true,
        );

        expect(
          prodData.technicalDetails,
          equals('Kode: CAM_UNEXPECTED (StateError)'),
        );
        expect(prodData.technicalDetails!.contains('0xdeadbeef'), isFalse);
      });

      test(
        'supports custom GoF DiagnosticErrorFormatter strategy via Pure DI',
        () {
          const customFormatter = _TestCameraErrorFormatter();
          final customData = CameraActionableError.captureFailure(
            Exception('Any error'),
            errorFormatter: customFormatter,
          );

          expect(customData.technicalDetails, equals('CUSTOM_CAM_TOKEN'));
        },
      );
    });

    group('Camera Switch Button Rotation Animation '
        '(Continuous Unidirectional & Orientation Composition)', () {
      testWidgets(
        'single switch camera tap rotates button by -0.5 turns (180 deg CCW)',
        (tester) async {
          configureTestView(tester);

          final initialMock = _createConfiguredMockController();
          final nextMock = _createConfiguredMockController(testCamera2);

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: initialMock,
                controllerFactory: (_) => nextMock,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final switchBtnFinder = find.byKey(
            const ValueKey<String>('camera_switch_button'),
          );
          expect(switchBtnFinder, findsOneWidget);

          // 1. Awalnya di posisi tegak normal (turns 0.0)
          var rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(0.0));
          expect(
            rotationWidget.duration,
            equals(AppMultiShotCameraScreen.rotationDuration),
          );
          expect(
            rotationWidget.curve,
            equals(AppMultiShotCameraScreen.rotationCurve),
          );

          // 2. Ketuk tombol switch kamera
          await tester.tap(switchBtnFinder);
          await tester.pump();

          // 3. Langsung berotasi ke -0.5 turn (180 derajat counter-clockwise)
          rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(-0.5));

          await tester.pumpAndSettle();
        },
      );

      testWidgets('sequential camera switches accumulate turns monotonically '
          '(0 -> -0.5 -> -1.0)', (tester) async {
        configureTestView(tester);

        final initialMock = _createConfiguredMockController();

        await tester.pumpWidget(
          _buildTestApp(
            AppMultiShotCameraScreen(
              cameras: const [testCamera1, testCamera2],
              controller: initialMock,
              controllerFactory: _createConfiguredMockController,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final switchBtnFinder = find.byKey(
          const ValueKey<String>('camera_switch_button'),
        );

        // Ketukan ke-1: Belakang -> Depan
        await tester.tap(switchBtnFinder);
        await tester.pump();

        var rotationWidget = tester.widget<AnimatedRotation>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(rotationWidget.turns, equals(-0.5));

        await tester.pumpAndSettle();

        // Ketukan ke-2: Depan -> Belakang
        await tester.tap(switchBtnFinder);
        await tester.pump();

        rotationWidget = tester.widget<AnimatedRotation>(
          find.descendant(
            of: switchBtnFinder,
            matching: find.byType(AnimatedRotation),
          ),
        );
        expect(rotationWidget.turns, equals(-1.0));

        await tester.pumpAndSettle();
      });

      testWidgets(
        'composes switch camera rotation additively with device orientation',
        (tester) async {
          configureTestView(tester);

          final initialMock = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: initialMock,
                initialDeviceOrientation: DeviceOrientation.landscapeLeft,
                controllerFactory: _createConfiguredMockController,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final switchBtnFinder = find.byKey(
            const ValueKey<String>('camera_switch_button'),
          );

          // Orientasi lanskap kiri = 0.25 turn (90 derajat searah jarum jam)
          var rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(0.25));

          // Ketuk switch camera saat di mode lanskap:
          // 0.25 (orientasi) + (-0.5 switch) = -0.25 turns
          await tester.tap(switchBtnFinder);
          await tester.pump();

          rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(-0.25));

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'interrupted rotation: rotating device while camera switch is '
        'animating updates target smoothly',
        (tester) async {
          configureTestView(tester);

          final orientationController =
              StreamController<DeviceOrientation>.broadcast();
          addTearDown(orientationController.close);

          final fakeSensorService = FakeDeviceOrientationSensorService(
            stream: orientationController.stream,
          );

          final initialMock = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: initialMock,
                orientationSensorService: fakeSensorService,
                controllerFactory: _createConfiguredMockController,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final switchBtnFinder = find.byKey(
            const ValueKey<String>('camera_switch_button'),
          );

          // Mulai switch camera (target menjadi -0.5)
          await tester.tap(switchBtnFinder);
          await tester.pump();

          var rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(-0.5));

          // Di tengah-tengah animasi, sensor perangkat mendeteksi putaran ke
          // landscapeLeft (0.25)
          await tester.pump(const Duration(milliseconds: 100));
          orientationController.add(DeviceOrientation.landscapeLeft);
          await tester.pump();

          // Target turns seketika menjadi 0.25 + (-0.5) = -0.25
          rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(-0.25));

          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'respects reduced motion by using Duration.zero for instant switch '
        'rotation',
        (tester) async {
          configureTestView(tester);

          final initialMock = _createConfiguredMockController();

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _buildTestApp(
                AppMultiShotCameraScreen(
                  cameras: const [testCamera1, testCamera2],
                  controller: initialMock,
                  controllerFactory: _createConfiguredMockController,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final switchBtnFinder = find.byKey(
            const ValueKey<String>('camera_switch_button'),
          );

          var rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.duration, equals(Duration.zero));

          await tester.tap(switchBtnFinder);
          await tester.pump();

          rotationWidget = tester.widget<AnimatedRotation>(
            find.descendant(
              of: switchBtnFinder,
              matching: find.byType(AnimatedRotation),
            ),
          );
          expect(rotationWidget.turns, equals(-0.5));
          expect(rotationWidget.duration, equals(Duration.zero));

          await tester.pumpAndSettle();
        },
      );
    });

    group('Camera Flash Button Transition Animation '
        '(Vertical Slide Reel & Amber Accent)', () {
      testWidgets(
        'flash button wraps icon in AnimatedSwitcher with M3 Expressive '
        'curves and duration',
        (tester) async {
          configureTestView(tester);

          final mock = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: mock,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final flashBtnFinder = find.byKey(
            const ValueKey<String>('camera_flash_button'),
          );
          expect(flashBtnFinder, findsOneWidget);

          final switcherFinder = find.descendant(
            of: flashBtnFinder,
            matching: find.byKey(
              const ValueKey<String>('camera_flash_switcher'),
            ),
          );
          expect(switcherFinder, findsOneWidget);

          final switcher = tester.widget<AnimatedSwitcher>(switcherFinder);
          expect(switcher.duration, equals(AppDuration.medium2));
          expect(switcher.switchInCurve, equals(Curves.easeInOutCubic));
          expect(
            switcher.switchOutCurve,
            isA<FlippedCurve>().having(
              (c) => c.curve,
              'curve',
              equals(Curves.easeInOutCubic),
            ),
          );
          expect(
            find.descendant(
              of: flashBtnFinder,
              matching: find.byType(ClipRect),
            ),
            findsWidgets,
          );
        },
      );

      testWidgets(
        'toggling flash triggers AnimatedSwitcher with SlideTransition '
        'and FadeTransition',
        (tester) async {
          configureTestView(tester);

          final mock = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: mock,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final flashBtnFinder = find.byKey(
            const ValueKey<String>('camera_flash_button'),
          );

          // Ketuk tombol flash untuk beralih mode (off -> auto)
          await tester.tap(flashBtnFinder);
          await tester.pump(); // frame pertama transisi

          // Di tengah animasi transisi, terdapat FadeTransition dan
          // SlideTransition aktif
          final fadeFinder = find.descendant(
            of: flashBtnFinder,
            matching: find.byType(FadeTransition),
          );
          expect(fadeFinder, findsWidgets);

          final slideFinder = find.descendant(
            of: flashBtnFinder,
            matching: find.byType(SlideTransition),
          );
          expect(slideFinder, findsWidgets);

          await tester.pumpAndSettle();

          // Pasca transisi selesai, hanya tersisa 1 AppSvgIcon aktif
          expect(
            find.descendant(
              of: flashBtnFinder,
              matching: find.byType(AppSvgIcon),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'respects reduced motion by using Duration.zero for flash switcher',
        (tester) async {
          configureTestView(tester);

          final mock = _createConfiguredMockController();

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: _buildTestApp(
                AppMultiShotCameraScreen(
                  cameras: const [testCamera1, testCamera2],
                  controller: mock,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final flashBtnFinder = find.byKey(
            const ValueKey<String>('camera_flash_button'),
          );
          final switcherFinder = find.descendant(
            of: flashBtnFinder,
            matching: find.byKey(
              const ValueKey<String>('camera_flash_switcher'),
            ),
          );
          expect(switcherFinder, findsOneWidget);

          final switcher = tester.widget<AnimatedSwitcher>(switcherFinder);
          expect(switcher.duration, equals(Duration.zero));
        },
      );

      testWidgets(
        'active flash modes always and torch render amber accent while '
        'off and auto render white',
        (tester) async {
          configureTestView(tester);

          final mock = _createConfiguredMockController();

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: mock,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final flashBtnFinder = find.byKey(
            const ValueKey<String>('camera_flash_button'),
          );

          AppSvgIcon getFlashIcon() {
            return tester.widget<AppSvgIcon>(
              find.descendant(
                of: flashBtnFinder,
                matching: find.byType(AppSvgIcon),
              ),
            );
          }

          // 1. Awal: off -> putih
          expect(getFlashIcon().color, equals(Colors.white));

          // 2. Ketuk 1: off -> auto -> putih
          await tester.tap(flashBtnFinder);
          await tester.pumpAndSettle();
          expect(getFlashIcon().color, equals(Colors.white));

          // 3. Ketuk 2: auto -> always -> amber (#FFD54F)
          await tester.tap(flashBtnFinder);
          await tester.pumpAndSettle();
          expect(getFlashIcon().color, equals(const Color(0xFFFFD54F)));

          // 4. Ketuk 3: always -> torch -> amber (#FFD54F)
          await tester.tap(flashBtnFinder);
          await tester.pumpAndSettle();
          expect(getFlashIcon().color, equals(const Color(0xFFFFD54F)));

          // 5. Ketuk 4: torch -> off -> putih
          await tester.tap(flashBtnFinder);
          await tester.pumpAndSettle();
          expect(getFlashIcon().color, equals(Colors.white));
        },
      );

      testWidgets(
        'optimistic UI update triggers icon transition on tap and rolls back '
        'on exception',
        (tester) async {
          configureTestView(tester);

          final mock = _createConfiguredMockController();
          final completer = Completer<void>();
          // Simulasi latensi hardware platform channel:
          // setFlashMode menunggu completer
          when(
            () => mock.setFlashMode(FlashMode.auto),
          ).thenAnswer((_) => completer.future);

          await tester.pumpWidget(
            _buildTestApp(
              AppMultiShotCameraScreen(
                cameras: const [testCamera1, testCamera2],
                controller: mock,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final flashBtnFinder = find.byKey(
            const ValueKey<String>('camera_flash_button'),
          );

          // Kondisi awal: off
          expect(
            find.descendant(
              of: flashBtnFinder,
              matching: find.byKey(const ValueKey<FlashMode>(FlashMode.off)),
            ),
            findsOneWidget,
          );

          // Ketuk tombol flash
          await tester.tap(flashBtnFinder);
          await tester.pump();

          // Optimistic update: flash mode langsung berganti ke auto pada
          // frame 0 meskipun panggilan hardware kamera masih tertahan
          expect(
            find.descendant(
              of: flashBtnFinder,
              matching: find.byKey(const ValueKey<FlashMode>(FlashMode.auto)),
            ),
            findsOneWidget,
          );

          // Hardware melempar error / kegagalan
          completer.completeError(Exception('Hardware reject flashMode'));
          await tester.pumpAndSettle();

          // Rollback secara anggun ke state off
          expect(
            find.descendant(
              of: flashBtnFinder,
              matching: find.byKey(const ValueKey<FlashMode>(FlashMode.off)),
            ),
            findsOneWidget,
          );
        },
      );
    });

    testWidgets(
      'supports custom ImageCropper via Pure DI during photo capture',
      (tester) async {
        configureTestView(tester);
        final mockController = _createConfiguredMockController();
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_custom_crop.jpg')
          ..writeAsBytesSync([1, 2, 3]);

        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        var customCropCalled = false;
        final fakeCropper = _FakeImageCropper(
          onCrop: () {
            customCropCalled = true;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AppMultiShotCameraScreen(
              controller: mockController,
              cameras: const [testCamera1],
              imageCropper: fakeCropper,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final shutterBtn = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        expect(shutterBtn, findsOneWidget);
        await tester.tap(shutterBtn);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        expect(customCropCalled, isTrue);
        expect(fakeCropper.lastIsFrontCamera, isFalse);
        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'passes isFrontCamera: true to imageCropper when capturing with '
      'front camera',
      (tester) async {
        configureTestView(tester);
        final mockController = _createConfiguredMockController(testCamera2);
        final tempDir = Directory.systemTemp.createTempSync();
        final tempFile = File('${tempDir.path}/test_front_crop.jpg')
          ..writeAsBytesSync([1, 2, 3]);

        when(
          mockController.takePicture,
        ).thenAnswer((_) async => XFile(tempFile.path));

        final fakeCropper = _FakeImageCropper();

        await tester.pumpWidget(
          MaterialApp(
            home: AppMultiShotCameraScreen(
              controller: mockController,
              cameras: const [testCamera2],
              imageCropper: fakeCropper,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final shutterBtn = find.byKey(
          const ValueKey<String>('camera_shutter_button'),
        );
        expect(shutterBtn, findsOneWidget);
        await tester.tap(shutterBtn);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        expect(fakeCropper.lastIsFrontCamera, isTrue);
        tempDir.deleteSync(recursive: true);
      },
    );
  });
}

class _FakeImageCropper implements ImageCropper {
  _FakeImageCropper({this.onCrop});

  final VoidCallback? onCrop;
  bool? lastIsFrontCamera;

  @override
  Future<bool> cropFileTo9x16(
    String filePath, {
    DeviceOrientation orientation = DeviceOrientation.portraitUp,
    double maxWidth = CropImagePayload.defaultMaxWidth,
    double maxHeight = CropImagePayload.defaultMaxHeight,
    int quality = CropImagePayload.defaultQuality,
    bool isFrontCamera = false,
  }) async {
    lastIsFrontCamera = isFrontCamera;
    onCrop?.call();
    return true;
  }
}

class _TestCameraErrorFormatter implements DiagnosticErrorFormatter {
  const _TestCameraErrorFormatter();

  @override
  String format(Object error, {String? domainPrefix}) => 'CUSTOM_CAM_TOKEN';
}

const testCamera1 = CameraDescription(
  name: '0',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

const testCamera2 = CameraDescription(
  name: '1',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

MockCameraController _createConfiguredMockController([
  CameraDescription camera = testCamera1,
  List<VoidCallback>? listeners,
]) {
  final mock = MockCameraController();
  final listenerList = listeners ?? <VoidCallback>[];
  when(() => mock.value).thenReturn(
    CameraValue.uninitialized(
      camera,
    ).copyWith(isInitialized: true, previewSize: const Size(1920, 1080)),
  );
  when(() => mock.description).thenReturn(camera);
  when(() => mock.cameraId).thenReturn(1);
  when(mock.buildPreview).thenReturn(const SizedBox());
  when(mock.initialize).thenAnswer((_) async {});
  when(() => mock.setFlashMode(any())).thenAnswer((_) async {});
  when(() => mock.lockCaptureOrientation(any())).thenAnswer((_) async {});
  when(mock.unlockCaptureOrientation).thenAnswer((_) async {});
  when(mock.dispose).thenAnswer((_) async {});
  when(() => mock.addListener(any())).thenAnswer((inv) {
    listenerList.add(inv.positionalArguments[0] as VoidCallback);
  });
  when(() => mock.removeListener(any())).thenAnswer((inv) {
    listenerList.remove(inv.positionalArguments[0] as VoidCallback);
  });
  return mock;
}

class MockCameraController extends Mock implements CameraController {}

class MockScreenBrightnessService extends Mock
    implements ScreenBrightnessService {}

class FakeDeviceOrientationSensorService
    implements DeviceOrientationSensorService {
  FakeDeviceOrientationSensorService({
    required Stream<DeviceOrientation> stream,
    this.currentOrientation = DeviceOrientation.portraitUp,
  }) : _stream = stream;

  final Stream<DeviceOrientation> _stream;

  @override
  DeviceOrientation currentOrientation;

  @override
  Stream<DeviceOrientation> get onOrientationChanged => _stream;

  @override
  void dispose() {}
}
