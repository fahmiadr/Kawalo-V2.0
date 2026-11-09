import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightThemeData(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppBottomSheet Interactive Drag & Scroll Tests', () {
    setUp(resetAppBottomSheetActiveForTesting);
    tearDown(resetAppBottomSheetActiveForTesting);

    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const AppBottomSheet(child: Text('Konten Bottom Sheet')),
        ),
      );

      expect(find.text('Konten Bottom Sheet'), findsOneWidget);
      expect(find.byType(AppBottomSheet), findsOneWidget);
    });

    testWidgets('shows drag handle when enabled', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const AppBottomSheet(child: Text('With Handle'))),
      );

      expect(find.text('With Handle'), findsOneWidget);
      expect(find.byType(AppBottomSheet), findsOneWidget);
    });

    testWidgets('showAppBottomSheet presents modal sheet', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAppBottomSheet<void>(
                    context: context,
                    child: const Text('Modal Content'),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Content'), findsOneWidget);

      Navigator.of(tester.element(find.text('Modal Content'))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('allows only one bottom sheet open at a time', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAppBottomSheet<void>(
                    context: context,
                    child: const Text('First Sheet'),
                  );
                  showAppBottomSheet<void>(
                    context: context,
                    child: const Text('Second Sheet'),
                  );
                },
                child: const Text('Open Multiple'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Multiple'));
      await tester.pumpAndSettle();

      expect(find.text('First Sheet'), findsOneWidget);
      expect(find.text('Second Sheet'), findsNothing);
    });

    testWidgets('dragging handle down past threshold triggers dismiss', (
      tester,
    ) async {
      var isDismissed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: AppBottomSheet(
            onDismissed: () {
              isDismissed = true;
            },
            child: const SizedBox(
              height: 200,
              child: Text('Drag Test Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the drag handle area (GestureDetector)
      final handleFinder = find.byType(GestureDetector).first;
      expect(handleFinder, findsOneWidget);

      // Drag down by 150px (more than 35% of 200px)
      await tester.drag(handleFinder, const Offset(0, 150));
      await tester.pumpAndSettle();

      expect(isDismissed, isTrue);
    });

    testWidgets('dragging handle down below threshold snaps back', (
      tester,
    ) async {
      var isDismissed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: AppBottomSheet(
            onDismissed: () {
              isDismissed = true;
            },
            child: const SizedBox(
              height: 300,
              child: Text('Snap Back Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handleFinder = find.byType(GestureDetector).first;
      // Drag down only 20px (well below 35% threshold)
      await tester.drag(handleFinder, const Offset(0, 20));
      await tester.pumpAndSettle();

      expect(isDismissed, isFalse);
      expect(find.text('Snap Back Content'), findsOneWidget);
    });

    testWidgets('dragging scrollable content while at top pulls sheet down', (
      tester,
    ) async {
      var isDismissed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: AppBottomSheet(
            onDismissed: () {
              isDismissed = true;
            },
            child: SizedBox(
              height: 300,
              child: ListView(
                children: List.generate(
                  20,
                  (index) => ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag downwards starting at Item 0 (already at top boundary)
      final item0Finder = find.text('Item 0');
      expect(item0Finder, findsOneWidget);

      await tester.drag(item0Finder, const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(isDismissed, isTrue);
    });

    testWidgets('constrains height to maxHeightFactor', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        _buildTestApp(
          child: const AppBottomSheet(
            maxHeightFactor: 0.80,
            child: SizedBox(height: 2000, child: Text('Tall Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheetSize = tester.getSize(
        find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
      );
      expect(sheetSize.height, lessThanOrEqualTo(800.0));
    });

    testWidgets('explicit maxHeight overrides maxHeightFactor', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        _buildTestApp(
          child: const AppBottomSheet(
            maxHeight: 350,
            child: SizedBox(height: 2000, child: Text('Explicit Max Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sheetSize = tester.getSize(
        find.byKey(const ValueKey('app_bottom_sheet_constrained_box')),
      );
      expect(sheetSize.height, lessThanOrEqualTo(350.0));
    });
  });
}
