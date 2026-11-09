import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_tooltip.dart';

/// Finder tombol tutup berbasis [AppTooltip] (M3E), karena `byTooltip`
/// hanya mengenali `Tooltip` Material.
Finder _closeButtonFinder() => find.byWidgetPredicate(
  (widget) => widget is AppTooltip && widget.message == 'Tutup penampil gambar',
);

void main() {
  group('AppImageViewer Tests', () {
    testWidgets('renders PageView, counter, and close button correctly', (
      tester,
    ) async {
      final imageUrls = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
        'https://example.com/3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      // Verify counter displays 1 / 3
      expect(find.text('1 / 3'), findsOneWidget);

      // Verify close button exists with tooltip
      expect(_closeButtonFinder(), findsOneWidget);

      // Verify PageView is rendered
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('respects initialIndex', (tester) async {
      final imageUrls = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
        'https://example.com/3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageViewer(imageUrls: imageUrls, initialIndex: 1),
          ),
        ),
      );

      // Verify counter starts at 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('swiping page updates counter', (tester) async {
      final imageUrls = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      expect(find.text('1 / 2'), findsOneWidget);

      // Drag left to transition to page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('close button pops navigator', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppImageViewer.show(context, imageUrls: imageUrls),
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      );

      // Tap to open viewer
      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsOneWidget);

      // Tap close button
      await tester.tap(_closeButtonFinder());
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsNothing);
    });

    testWidgets('Escape key closes viewer', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppImageViewer.show(context, imageUrls: imageUrls),
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      );

      // Tap to open viewer
      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsOneWidget);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsNothing);
    });

    testWidgets('downward swipe dismisses viewer', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppImageViewer.show(context, imageUrls: imageUrls),
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsOneWidget);

      // Swipe down by 250 pixels starting from top area of screen
      await tester.dragFrom(const Offset(400, 100), const Offset(0, 250));
      await tester.pumpAndSettle();

      // Viewer should be dismissed
      expect(find.byType(AppImageViewer), findsNothing);
    });

    testWidgets('upward swipe does not dismiss viewer', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppImageViewer.show(context, imageUrls: imageUrls),
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      expect(find.byType(AppImageViewer), findsOneWidget);

      // Swipe upward by -250 pixels
      await tester.drag(find.byType(PageView), const Offset(0, -250));
      await tester.pumpAndSettle();

      // Viewer must NOT be dismissed
      expect(find.byType(AppImageViewer), findsOneWidget);
    });

    testWidgets('double tap zooms in and zooms out', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      final center = tester.getCenter(find.byType(InteractiveViewer));

      // Double tap to zoom in
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = iv.transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.5));

      // Double tap again to reset zoom
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.05));
    });

    testWidgets('pinch to zoom at initial scale 1.0 increases scale', (
      tester,
    ) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      final center = tester.getCenter(find.byType(InteractiveViewer));
      final touch1 = await tester.startGesture(center - const Offset(20, 0));
      final touch2 = await tester.startGesture(center + const Offset(20, 0));

      await touch1.moveBy(const Offset(-60, -30));
      await touch2.moveBy(const Offset(60, 30));
      await tester.pump();

      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = iv.transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.05));
    });

    testWidgets('purely horizontal pinch to zoom increases scale', (
      tester,
    ) async {
      final imageUrls = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      final center = tester.getCenter(find.byType(InteractiveViewer));
      final touch1 = await tester.startGesture(center - const Offset(20, 0));
      final touch2 = await tester.startGesture(center + const Offset(20, 0));

      // Purely horizontal pinch (dy == 0)
      await touch1.moveBy(const Offset(-80, 0));
      await touch2.moveBy(const Offset(80, 0));
      await tester.pump();

      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = iv.transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.05));
    });

    testWidgets('asymmetric horizontal pinch where one finger moves first', (
      tester,
    ) async {
      final imageUrls = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      final center = tester.getCenter(find.byType(InteractiveViewer));
      final touch1 = await tester.startGesture(center - const Offset(20, 0));
      // Finger 1 touches down and moves slightly (within slop)
      // before finger 2 touches
      await touch1.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 30));

      final touch2 = await tester.startGesture(center + const Offset(20, 0));
      await touch2.moveBy(const Offset(40, 0));
      await touch1.moveBy(const Offset(-40, 0));
      await tester.pump();

      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = iv.transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.05));
    });

    testWidgets('vertical pan when zoomed shifts position without resetting', (
      tester,
    ) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      final center = tester.getCenter(find.byType(InteractiveViewer));

      // Double tap to zoom in
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      final iv = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = iv.transformationController!;
      final initialTy = controller.value.storage[13];

      // Pan vertically by -80 pixels (drag upwards)
      await tester.drag(find.byType(InteractiveViewer), const Offset(0, -80));
      await tester.pumpAndSettle();

      final newTy = controller.value.storage[13];
      // newTy must have changed and not reset to initialTy
      expect(newTy, isNot(equals(initialTy)));
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.5));
    });

    testWidgets('tapping backdrop or image toggles top chrome', (tester) async {
      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
        ),
      );

      // Initially visible
      final animatedOpacityFinder = find.byType(AnimatedOpacity);
      expect(animatedOpacityFinder, findsOneWidget);
      expect(
        tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity,
        equals(1.0),
      );

      // Tap to hide chrome
      final center = tester.getCenter(find.byType(InteractiveViewer));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity,
        equals(0.0),
      );

      // Tap again to show chrome
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(animatedOpacityFinder).opacity,
        equals(1.0),
      );
    });

    testWidgets(
      'renders seamlessly with dynamic colors in both Light and Dark themes',
      (tester) async {
        final imageUrls = ['https://example.com/1.jpg'];

        // 1. Light Mode
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppIconButton), findsOneWidget);
        expect(find.text('1 / 1'), findsOneWidget);

        // 2. Dark Mode
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppIconButton), findsOneWidget);
        expect(find.text('1 / 1'), findsOneWidget);
      },
    );

    testWidgets(
      'configures light status bar icons for dark background overlay',
      (tester) async {
        final imageUrls = ['https://example.com/1.jpg'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
          ),
        );
        await tester.pumpAndSettle();

        final regionFinder = find.byType(AnnotatedRegion<SystemUiOverlayStyle>);
        expect(regionFinder, findsOneWidget);

        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          regionFinder,
        );
        expect(region.value.statusBarIconBrightness, equals(Brightness.light));
        expect(region.value.statusBarBrightness, equals(Brightness.dark));
      },
    );

    testWidgets('enables immersiveSticky system UI mode on open and restores '
        'edgeToEdge on dispose', (tester) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      final imageUrls = ['https://example.com/1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppImageViewer.show(context, imageUrls: imageUrls),
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
              call.method == 'SystemChrome.setEnabledSystemUIMode' &&
              call.arguments == 'SystemUiMode.immersiveSticky',
        ),
        isTrue,
      );

      await tester.tap(_closeButtonFinder());
      await tester.pumpAndSettle();

      expect(
        log.any(
          (call) =>
              call.method == 'SystemChrome.setEnabledSystemUIMode' &&
              call.arguments == 'SystemUiMode.edgeToEdge',
        ),
        isTrue,
      );
    });

    testWidgets(
      'top chrome fades out quickly during downward swipe-to-dismiss',
      (tester) async {
        final imageUrls = ['https://example.com/1.jpg'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AppImageViewer(imageUrls: imageUrls)),
          ),
        );
        await tester.pumpAndSettle();

        final topChromeFinder = find.ancestor(
          of: find.byType(ValueListenableBuilder<bool>),
          matching: find.byType(Opacity),
        );
        expect(topChromeFinder, findsOneWidget);

        Opacity getOpacity() => tester.widget<Opacity>(topChromeFinder);

        expect(getOpacity().opacity, equals(1.0));

        // Start dragging downward from top area
        final gesture = await tester.startGesture(const Offset(400, 100));
        // Move in continuous steps over time
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(0, 4));
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Opacity should have decreased (drag ~40px)
        expect(getOpacity().opacity, lessThan(1.0));

        // Drag further to reach >= 80dp
        for (var i = 0; i < 15; i++) {
          await gesture.moveBy(const Offset(0, 4));
          await tester.pump(const Duration(milliseconds: 16));
        }

        // At >= 80dp drag, opacity reaches 0.0
        expect(getOpacity().opacity, equals(0.0));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
