import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_photo_thumbnail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

Widget _buildThumbnailTestApp({required Widget child}) {
  return MaterialApp(
    builder: (context, c) => M3ETheme(data: AppTheme.m3eLight(), child: c!),
    home: Scaffold(
      body: Center(child: SizedBox(width: 180, height: 180, child: child)),
    ),
  );
}

void main() {
  group('InformationPhotoThumbnail Widget Tests', () {
    testWidgets('renders loaded photo with badge, remove button, and options', (
      tester,
    ) async {
      var tapped = false;
      var removed = false;
      var optionsClicked = false;

      const item = InformationFormMediaItem(
        id: 'photo_1',
        name: 'dokumentasi.jpg',
        path: '/dummy/path.jpg',
      );

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 0,
            isSubmitting: false,
            onTap: () => tapped = true,
            onRemove: () => removed = true,
            onMoreOptions: () => optionsClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge '1'
      expect(find.text('1'), findsOneWidget);

      // Buttons
      expect(find.bySemanticsLabel('Hapus foto 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Opsi foto 1'), findsOneWidget);

      // Tap main thumbnail
      await tester.tap(find.byKey(const ValueKey<String>('photo_thumbnail_0')));
      expect(tapped, isTrue);

      // Tap remove
      await tester.tap(find.bySemanticsLabel('Hapus foto 1'));
      expect(removed, isTrue);

      // Tap options
      await tester.tap(find.bySemanticsLabel('Opsi foto 1'));
      expect(optionsClicked, isTrue);
    });

    testWidgets(
      'renders loading state with AppLoadingIndicator only (no text label)',
      (tester) async {
        var tapped = false;
        var removed = false;

        final item = InformationFormMediaItem.loading(id: 'temp_photo');

        await tester.pumpWidget(
          _buildThumbnailTestApp(
            child: InformationPhotoThumbnail(
              item: item,
              index: 1,
              isSubmitting: false,
              onTap: () => tapped = true,
              onRemove: () => removed = true,
              onMoreOptions: () {},
            ),
          ),
        );
        await tester.pump();

        // AppLoadingIndicator is displayed
        expect(find.byType(AppLoadingIndicator), findsOneWidget);

        // Badge '2' is visible
        expect(find.text('2'), findsOneWidget);

        // More options button is hidden during loading
        expect(find.bySemanticsLabel('Opsi foto 2'), findsNothing);

        // Tap on loading thumbnail is disabled
        await tester.tap(
          find.byKey(const ValueKey<String>('photo_thumbnail_1')),
          warnIfMissed: false,
        );
        expect(tapped, isFalse);

        // Quick cancel/remove is still accessible during loading
        await tester.tap(find.bySemanticsLabel('Hapus foto 2'));
        expect(removed, isTrue);
      },
    );

    testWidgets('explicit isLoading overrides item properties', (tester) async {
      const item = InformationFormMediaItem(id: 'photo_2', name: 'gambar.png');

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 2,
            isSubmitting: false,
            isLoading: true,
            onTap: () {},
            onRemove: () {},
            onMoreOptions: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Opsi foto 3'), findsNothing);
    });

    testWidgets('renders Image.memory with frameBuilder without errors', (
      tester,
    ) async {
      // 1x1 transparent PNG bytes
      final transparentPng = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      final item = InformationFormMediaItem(
        id: 'memory_1',
        name: 'memory.png',
        bytes: transparentPng,
      );

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 0,
            isSubmitting: false,
            onTap: () {},
            onRemove: () {},
            onMoreOptions: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('disables all interactions when isSubmitting is true', (
      tester,
    ) async {
      var tapped = false;
      var removed = false;
      var optionsClicked = false;

      const item = InformationFormMediaItem(
        id: 'photo_submitting',
        name: 'submit.jpg',
      );

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 0,
            isSubmitting: true,
            onTap: () => tapped = true,
            onRemove: () => removed = true,
            onMoreOptions: () => optionsClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap thumbnail
      await tester.tap(find.byKey(const ValueKey<String>('photo_thumbnail_0')));
      expect(tapped, isFalse);

      // Tap remove
      await tester.tap(find.bySemanticsLabel('Hapus foto 1'));
      expect(removed, isFalse);

      // Tap options
      await tester.tap(find.bySemanticsLabel('Opsi foto 1'));
      expect(optionsClicked, isFalse);
    });

    testWidgets(
      'renders Hero widget without redundant inner ClipRRect for clean '
      'morphing',
      (tester) async {
        const item = InformationFormMediaItem(
          id: 'photo_hero',
          name: 'foto.jpg',
          path: '/dummy/foto.jpg',
        );

        await tester.pumpWidget(
          _buildThumbnailTestApp(
            child: InformationPhotoThumbnail(
              item: item,
              index: 0,
              heroTagPrefix: 'info_photo_test',
              isSubmitting: false,
              onTap: () {},
              onRemove: () {},
              onMoreOptions: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Hero widget is rendered with matching tag
        final heroFinder = find.byType(Hero);
        expect(heroFinder, findsOneWidget);
        final heroWidget = tester.widget<Hero>(heroFinder);
        expect(heroWidget.tag, 'info_photo_test_0');

        // Verify no redundant inner ClipRRect exists inside Hero
        final innerClip = find.descendant(
          of: heroFinder,
          matching: find.byType(ClipRRect),
        );
        expect(innerClip, findsNothing);

        // Verify AppMorphingSurface's ClipRRect maintains restingBorderRadius
        final surfaceClip = find.byType(ClipRRect);
        expect(surfaceClip, findsOneWidget);
        expect(
          tester.widget<ClipRRect>(surfaceClip).borderRadius,
          AppRadius.borderMedium,
        );
      },
    );

    testWidgets('compresses corner radius from borderMedium to borderSmall '
        'when pressed using spring physics', (tester) async {
      const item = InformationFormMediaItem(
        id: 'photo_press',
        name: 'foto.jpg',
        path: '/dummy/foto.jpg',
      );

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 0,
            isSubmitting: false,
            onTap: () {},
            onRemove: () {},
            onMoreOptions: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At rest: outer ClipRRect has AppRadius.borderMedium (12dp)
      final outerClipFinder = find.byType(ClipRRect).first;
      expect(
        tester.widget<ClipRRect>(outerClipFinder).borderRadius,
        AppRadius.borderMedium,
      );

      // Press down on thumbnail
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey<String>('photo_thumbnail_0')),
        ),
      );
      await tester.pumpAndSettle();

      // Pressed: outer ClipRRect compresses to AppRadius.borderSmall (8dp)
      expect(
        tester.widget<ClipRRect>(outerClipFinder).borderRadius,
        AppRadius.borderSmall,
      );

      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();

      // Returns to resting borderMedium (12dp)
      expect(
        tester.widget<ClipRRect>(outerClipFinder).borderRadius,
        AppRadius.borderMedium,
      );
    });

    testWidgets('enables Material Ink Ripple with M3EStateLayerOverlay', (
      tester,
    ) async {
      const item = InformationFormMediaItem(
        id: 'photo_ink',
        name: 'foto.jpg',
        path: '/dummy/foto.jpg',
      );

      await tester.pumpWidget(
        _buildThumbnailTestApp(
          child: InformationPhotoThumbnail(
            item: item,
            index: 0,
            isSubmitting: false,
            onTap: () {},
            onRemove: () {},
            onMoreOptions: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(M3EStateLayerOverlay), findsOneWidget);
    });
  });
}
