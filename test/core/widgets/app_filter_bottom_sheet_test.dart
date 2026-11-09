import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_filter_bottom_sheet.dart';

void main() {
  group('AppFilterBottomSheet Generic Slot Widget Tests', () {
    testWidgets(
      'renders title, subtitle, reset, custom slot, and apply button',
      (tester) async {
        var resetCalled = false;
        var applyCalled = false;

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: Scaffold(
              body: AppFilterBottomSheet(
                title: 'Filter Kategori',
                subtitle: 'Pilih kategori item',
                isResetEnabled: true,
                onReset: () => resetCalled = true,
                onApply: () => applyCalled = true,
                child: const Text('Slot Konten Filter Khusus'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Filter Kategori'), findsOneWidget);
        expect(find.text('Pilih kategori item'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
        expect(find.text('Slot Konten Filter Khusus'), findsOneWidget);
        expect(find.text('Terapkan'), findsOneWidget);

        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(resetCalled, isTrue);

        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
        expect(applyCalled, isTrue);
      },
    );

    testWidgets('disables reset button when isResetEnabled is false', (
      tester,
    ) async {
      var resetCalled = false;

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: AppFilterBottomSheet(
              title: 'Filter Status',
              onReset: () => resetCalled = true,
              child: const Text('Isi status'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(resetCalled, isFalse);
    });

    testWidgets('respects isScrollable false without SingleChildScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppFilterBottomSheet(
              title: 'Filter Tanpa Scroll',
              isScrollable: false,
              child: Text('Konten Non-Scroll'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter Tanpa Scroll'), findsOneWidget);
      expect(find.text('Konten Non-Scroll'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('respects isRoot false without outer SafeArea or ClipRect', (
      tester,
    ) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppFilterBottomSheet(
              title: 'Sub-View Filter',
              isRoot: false,
              child: Text('Konten Non-Root'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sub-View Filter'), findsOneWidget);
      expect(find.text('Konten Non-Root'), findsOneWidget);
      expect(find.byType(SafeArea), findsNothing);
      expect(find.byType(AnimatedSize), findsNothing);
    });

    testWidgets('respects custom contentPadding', (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: const Scaffold(
            body: AppFilterBottomSheet(
              title: 'Filter Padding',
              contentPadding: EdgeInsets.zero,
              child: Text('Konten Padding Nol'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter Padding'), findsOneWidget);
      expect(find.text('Konten Padding Nol'), findsOneWidget);
    });

    testWidgets('opens via showAppFilterBottomSheet helper', (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAppFilterBottomSheet<void>(
                  context: context,
                  child: const AppFilterBottomSheet(
                    title: 'Filter Modal Pop',
                    child: Text('Konten Popup'),
                  ),
                ),
                child: const Text('Buka Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Modal Pop'), findsOneWidget);
      expect(find.text('Konten Popup'), findsOneWidget);
      expect(find.text('Terapkan'), findsOneWidget);
    });

    testWidgets('keeps apply button sticky and visible when child is tall', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: AppFilterBottomSheet(
              title: 'Sticky Test',
              child: Column(
                children: List.generate(
                  30,
                  (i) => SizedBox(height: 50, child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sticky Test'), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Terapkan'), findsOneWidget);

      // Scroll the middle list
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Apply button remains sticky and visible
      expect(find.text('Terapkan'), findsOneWidget);
    });

    testWidgets(
      'expand false hugs content while expand true fills available height',
      (tester) async {
        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: const AppFilterBottomSheet(
                    title: 'Wrap Test',
                    child: SizedBox(height: 80, child: Text('Small Content')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nonExpandedFinder = find.byType(AppFilterBottomSheet);
        final nonExpandedHeight = tester.getSize(nonExpandedFinder).height;
        // In 500 max height container, wrap content should be much less
        // than 500.
        expect(nonExpandedHeight, lessThan(400.0));

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: const AppFilterBottomSheet(
                    title: 'Expand Test',
                    expand: true,
                    child: SizedBox(height: 80, child: Text('Small Content')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expandedFinder = find.byType(AppFilterBottomSheet);
        final expandedHeight = tester.getSize(expandedFinder).height;
        // When expand is true, it fills available height (500).
        expect(expandedHeight, equals(500.0));
      },
    );
  });
}
