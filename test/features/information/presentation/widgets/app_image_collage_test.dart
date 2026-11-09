import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Widget _buildCollageTestApp({
  required List<String> imageUrls,
  required ValueChanged<int> onImageTap,
  double height = 240,
}) {
  return MaterialApp(
    builder: (context, child) =>
        M3ETheme(data: AppTheme.m3eLight(), child: child!),
    home: Scaffold(
      body: AppImageCollage(
        imageUrls: imageUrls,
        onImageTap: onImageTap,
        height: height,
      ),
    ),
  );
}

void main() {
  group('AppImageCollage Tests', () {
    testWidgets('renders SizedBox.shrink when imageUrls is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCollageTestApp(imageUrls: const [], onImageTap: (_) {}),
      );

      expect(find.byType(AppImageCollage), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('renders single tile for 1 image', (tester) async {
      final handle = tester.ensureSemantics();
      int? tappedIndex;
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const ['https://example.com/1.jpg'],
          onImageTap: (index) => tappedIndex = index,
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 1 dari 1'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Foto 1 dari 1'));
      expect(tappedIndex, 0);
      handle.dispose();
    });

    testWidgets('renders 2 tiles side-by-side for 2 images', (tester) async {
      final handle = tester.ensureSemantics();
      int? tappedIndex;
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
          ],
          onImageTap: (index) => tappedIndex = index,
        ),
      );

      expect(find.bySemanticsLabel('Foto 1 dari 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 2 dari 2'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Foto 2 dari 2'));
      expect(tappedIndex, 1);
      handle.dispose();
    });

    testWidgets('renders 3 tiles with M3 Expressive split for 3 images', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? tappedIndex;
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
            'https://example.com/3.jpg',
          ],
          onImageTap: (index) => tappedIndex = index,
        ),
      );

      expect(find.bySemanticsLabel('Foto 1 dari 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 2 dari 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 3 dari 3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Foto 3 dari 3'));
      expect(tappedIndex, 2);
      handle.dispose();
    });

    testWidgets('renders 4 tiles without +N overlay for 4 images', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
            'https://example.com/3.jpg',
            'https://example.com/4.jpg',
          ],
          onImageTap: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Foto 1 dari 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 4 dari 4'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
      handle.dispose();
    });

    testWidgets('renders 4 tiles with +N overlay for 5+ images', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? tappedIndex;
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
            'https://example.com/3.jpg',
            'https://example.com/4.jpg',
            'https://example.com/5.jpg',
            'https://example.com/6.jpg',
          ],
          onImageTap: (index) => tappedIndex = index,
        ),
      );

      // Total 6 images -> tile 4 shows +3
      expect(find.text('+3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Foto 4 dari 6, dan 3 foto lainnya'),
        findsOneWidget,
      );

      await tester.tap(
        find.bySemanticsLabel('Foto 4 dari 6, dan 3 foto lainnya'),
      );
      expect(tappedIndex, 3);
      handle.dispose();
    });

    testWidgets('uses pressedScale 1.0 and materialInk true on AppTappable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCollageTestApp(
          imageUrls: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
          ],
          onImageTap: (_) {},
        ),
      );

      final tappables = tester
          .widgetList<AppTappable>(find.byType(AppTappable))
          .toList();
      expect(tappables, hasLength(2));
      for (final tappable in tappables) {
        expect(tappable.pressedScale, 1.0);
        expect(tappable.materialInk, isTrue);
      }
      expect(find.byType(M3EStateLayerOverlay), findsNWidgets(2));
    });

    testWidgets(
      'outer corners morph to 8dp on press while inner corners remain at 4dp',
      (tester) async {
        await tester.pumpWidget(
          _buildCollageTestApp(
            imageUrls: const [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
            ],
            onImageTap: (_) {},
          ),
        );

        // Verify resting radius of Tile 0
        ClipRRect getTile0Clip() {
          return tester.widget<ClipRRect>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('collage_tile_0')),
              matching: find.byType(ClipRRect),
            ),
          );
        }

        final initialClip = getTile0Clip();
        final initialRadius = initialClip.borderRadius as BorderRadius;
        expect(initialRadius.topLeft.x, 12.0);
        expect(initialRadius.bottomLeft.x, 12.0);
        expect(initialRadius.topRight.x, 4.0);
        expect(initialRadius.bottomRight.x, 4.0);

        // Press down on tile 0
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(const ValueKey<String>('collage_tile_0')),
          ),
        );
        await tester.pumpAndSettle();

        final pressedClip = getTile0Clip();
        final pressedRadius = pressedClip.borderRadius as BorderRadius;

        // Outer corners compress from 12dp to 8dp
        expect(pressedRadius.topLeft.x, 8.0);
        expect(pressedRadius.bottomLeft.x, 8.0);

        // Inner junction corners remain firmly at 4.0dp
        expect(pressedRadius.topRight.x, 4.0);
        expect(pressedRadius.bottomRight.x, 4.0);

        // Release gesture and settle
        await gesture.up();
        await tester.pumpAndSettle();

        final restoredClip = getTile0Clip();
        final restoredRadius = restoredClip.borderRadius as BorderRadius;
        expect(restoredRadius.topLeft.x, 12.0);
        expect(restoredRadius.bottomLeft.x, 12.0);
        expect(restoredRadius.topRight.x, 4.0);
        expect(restoredRadius.bottomRight.x, 4.0);
      },
    );

    testWidgets(
      'single image tile morphs all four corners from 12dp to 8dp on press',
      (tester) async {
        await tester.pumpWidget(
          _buildCollageTestApp(
            imageUrls: const ['https://example.com/1.jpg'],
            onImageTap: (_) {},
          ),
        );

        ClipRRect getTileClip() {
          return tester.widget<ClipRRect>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('collage_tile_0')),
              matching: find.byType(ClipRRect),
            ),
          );
        }

        final initialRadius = getTileClip().borderRadius as BorderRadius;
        expect(initialRadius.topLeft.x, 12.0);
        expect(initialRadius.topRight.x, 12.0);
        expect(initialRadius.bottomLeft.x, 12.0);
        expect(initialRadius.bottomRight.x, 12.0);

        // Press down
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(const ValueKey<String>('collage_tile_0')),
          ),
        );
        await tester.pumpAndSettle();

        final pressedRadius = getTileClip().borderRadius as BorderRadius;
        expect(pressedRadius.topLeft.x, 8.0);
        expect(pressedRadius.topRight.x, 8.0);
        expect(pressedRadius.bottomLeft.x, 8.0);
        expect(pressedRadius.bottomRight.x, 8.0);

        // Release
        await gesture.up();
        await tester.pumpAndSettle();

        final restoredRadius = getTileClip().borderRadius as BorderRadius;
        expect(restoredRadius.topLeft.x, 12.0);
        expect(restoredRadius.topRight.x, 12.0);
        expect(restoredRadius.bottomLeft.x, 12.0);
        expect(restoredRadius.bottomRight.x, 12.0);
      },
    );
  });
}
