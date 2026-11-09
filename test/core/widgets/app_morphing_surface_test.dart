import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_morphing_surface.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    builder: (context, c) => M3ETheme(data: AppTheme.m3eLight(), child: c!),
    home: Scaffold(
      body: Center(child: SizedBox(width: 150, height: 150, child: child)),
    ),
  );
}

void main() {
  group('AppMorphingSurface Widget Tests', () {
    testWidgets(
      'compresses perimeter corners from 12dp to 8dp on press and rebounds',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _buildTestApp(
            child: AppMorphingSurface(
              key: const ValueKey<String>('morph_surface'),
              onTap: () => tapped = true,
              child: const ColoredBox(color: Colors.blue),
            ),
          ),
        );
        await tester.pumpAndSettle();

        ClipRRect getClip() => tester.widget<ClipRRect>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('morph_surface')),
            matching: find.byType(ClipRRect),
          ),
        );

        // Resting: 12dp all corners
        final initialRadius = getClip().borderRadius as BorderRadius;
        expect(initialRadius.topLeft.x, 12.0);
        expect(initialRadius.topRight.x, 12.0);
        expect(initialRadius.bottomLeft.x, 12.0);
        expect(initialRadius.bottomRight.x, 12.0);

        // Press down
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey<String>('morph_surface'))),
        );
        await tester.pumpAndSettle();

        // Pressed: 8dp all corners
        final pressedRadius = getClip().borderRadius as BorderRadius;
        expect(pressedRadius.topLeft.x, 8.0);
        expect(pressedRadius.topRight.x, 8.0);
        expect(pressedRadius.bottomLeft.x, 8.0);
        expect(pressedRadius.bottomRight.x, 8.0);

        // Release
        await gesture.up();
        await tester.pumpAndSettle();

        // Restored: 12dp all corners
        final restoredRadius = getClip().borderRadius as BorderRadius;
        expect(restoredRadius.topLeft.x, 12.0);
        expect(restoredRadius.topRight.x, 12.0);
        expect(restoredRadius.bottomLeft.x, 12.0);
        expect(restoredRadius.bottomRight.x, 12.0);
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'preserves inner junction corners at 4dp while outer corners compress',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: AppMorphingSurface(
              key: const ValueKey<String>('asymmetric_surface'),
              onTap: () {},
              restingBorderRadius: const BorderRadius.only(
                topLeft: AppRadius.radiusMedium, // 12dp
                bottomLeft: AppRadius.radiusMedium, // 12dp
                topRight: AppRadius.radiusExtraSmall, // 4dp
                bottomRight: AppRadius.radiusExtraSmall, // 4dp
              ),
              child: const ColoredBox(color: Colors.green),
            ),
          ),
        );
        await tester.pumpAndSettle();

        ClipRRect getClip() => tester.widget<ClipRRect>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('asymmetric_surface')),
            matching: find.byType(ClipRRect),
          ),
        );

        // Press down
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(const ValueKey<String>('asymmetric_surface')),
          ),
        );
        await tester.pumpAndSettle();

        final pressedRadius = getClip().borderRadius as BorderRadius;
        // Outer corners compressed to 8dp
        expect(pressedRadius.topLeft.x, 8.0);
        expect(pressedRadius.bottomLeft.x, 8.0);

        // Inner junction corners preserved firmly at 4dp
        expect(pressedRadius.topRight.x, 4.0);
        expect(pressedRadius.bottomRight.x, 4.0);

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('renders M3EStateLayerOverlay and uses pressedScale 1.0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const AppMorphingSurface(child: ColoredBox(color: Colors.red)),
        ),
      );

      final tappable = tester.widget<AppTappable>(find.byType(AppTappable));
      expect(tappable.pressedScale, 1.0);
      expect(tappable.materialInk, isTrue);
      expect(find.byType(M3EStateLayerOverlay), findsOneWidget);
    });

    testWidgets(
      'overlay button clicks execute independently without surface onTap',
      (tester) async {
        var surfaceTapped = false;
        var buttonClicked = false;

        await tester.pumpWidget(
          _buildTestApp(
            child: AppMorphingSurface(
              key: const ValueKey<String>('overlay_test_surface'),
              onTap: () => surfaceTapped = true,
              overlay: Positioned(
                top: 8,
                right: 8,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: AppIconButton(
                    onPressed: () => buttonClicked = true,
                    icon: const Icon(Icons.close, size: 16),
                    semanticLabel: 'Tombol silang',
                  ),
                ),
              ),
              child: const ColoredBox(color: Colors.yellow),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap overlay button
        await tester.tap(find.bySemanticsLabel('Tombol silang'));
        expect(buttonClicked, isTrue);
        expect(surfaceTapped, isFalse);

        // Tap surface background
        await tester.tap(
          find.byKey(const ValueKey<String>('overlay_test_surface')),
        );
        expect(surfaceTapped, isTrue);
      },
    );

    testWidgets('animates dynamic border radius matching morphing state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: AppMorphingSurface(
            key: const ValueKey<String>('border_surface'),
            onTap: () {},
            border: const BorderSide(color: Colors.white, width: 2),
            child: const ColoredBox(color: Colors.blue),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BoxDecoration getBorderDecoration() {
        final decoratedBox = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('border_surface')),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.position == DecorationPosition.foreground,
            ),
          ),
        );
        return decoratedBox.decoration as BoxDecoration;
      }

      // Resting: 12dp
      expect(
        (getBorderDecoration().borderRadius! as BorderRadius).topLeft.x,
        12.0,
      );

      // Press down
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('border_surface'))),
      );
      await tester.pumpAndSettle();

      // Pressed: 8dp
      expect(
        (getBorderDecoration().borderRadius! as BorderRadius).topLeft.x,
        8.0,
      );

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      // Restored: 12dp
      expect(
        (getBorderDecoration().borderRadius! as BorderRadius).topLeft.x,
        12.0,
      );
    });
  });
}
