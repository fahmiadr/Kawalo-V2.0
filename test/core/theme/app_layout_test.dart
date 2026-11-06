import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';

void main() {
  group('AppLayout Unit & Widget Tests', () {
    test('Breakpoints have exact M3 token values', () {
      expect(AppLayout.compactBreakpoint, 600.0);
      expect(AppLayout.mediumBreakpoint, 840.0);
      expect(AppLayout.expandedBreakpoint, 1200.0);
    });

    test('Layout constraints match M3 design system values', () {
      expect(AppLayout.maxContainerWidth, 1199.0);
      expect(AppLayout.contentMaxWidth, 600.0);
      expect(AppLayout.fixedPaneWidth, 360.0);
      expect(AppLayout.paneSpacer, AppSpacing.space300);
    });

    test('Responsive horizontal margins map correctly across breakpoints', () {
      expect(AppLayout.marginCompact, 16.0);
      expect(AppLayout.marginMediumExpanded, 24.0);

      // Compact (< 600dp)
      expect(AppLayout.horizontalMargin(360), 16.0);
      expect(AppLayout.horizontalMargin(599), 16.0);

      // Medium (600 - 839dp)
      expect(AppLayout.horizontalMargin(600), 24.0);
      expect(AppLayout.horizontalMargin(800), 24.0);

      // Expanded (>= 840dp)
      expect(AppLayout.horizontalMargin(840), 24.0);
      expect(AppLayout.horizontalMargin(1200), 24.0);
    });

    test('Window Size Classes classify widths correctly', () {
      expect(AppLayout.getWindowSizeClass(390), AppWindowSizeClass.compact);
      expect(AppLayout.getWindowSizeClass(700), AppWindowSizeClass.medium);
      expect(AppLayout.getWindowSizeClass(900), AppWindowSizeClass.expanded);
      expect(AppLayout.getWindowSizeClass(1400), AppWindowSizeClass.expanded);

      expect(AppLayout.isCompact(390), isTrue);
      expect(AppLayout.isCompact(700), isFalse);

      expect(AppLayout.isMedium(700), isTrue);
      expect(AppLayout.isMedium(390), isFalse);
      expect(AppLayout.isMedium(900), isFalse);

      expect(AppLayout.isExpanded(900), isTrue);
      expect(AppLayout.isExpanded(700), isFalse);
    });

    test('Supported orientations contain all 4 directions', () {
      expect(AppLayout.supportedOrientations, [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });

    testWidgets('Orientation helpers detect landscape and portrait properly',
        (tester) async {
      // Test portrait view
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      late bool isPortrait;
      late bool isLandscape;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPortrait = AppLayout.isPortrait(context);
              isLandscape = AppLayout.isLandscape(context);
              return const Scaffold(body: Center(child: Text('Layout Test')));
            },
          ),
        ),
      );

      expect(isPortrait, isTrue);
      expect(isLandscape, isFalse);

      // Test landscape view
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pump();

      expect(isPortrait, isFalse);
      expect(isLandscape, isTrue);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    test('Scroll clearance and bottom padding tokens match specifications', () {
      expect(AppLayout.standardBottomPadding, AppSpacing.space200);
      expect(AppLayout.fabScrollClearance, 120.0);
      expect(AppLayout.toolbarScrollClearanceBase, 96.0);
    });

    testWidgets('toolbarScrollClearance factors in safe area bottom padding',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      late double clearance;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              clearance = AppLayout.toolbarScrollClearance(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(clearance, equals(96.0 + 34.0));
    });
  });
}
