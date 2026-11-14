import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_card.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';

const _item = InformationItemEntity(
  id: 'info-1',
  title: 'Pengumuman Penting',
  text: 'Baris pertama.\nBaris kedua yang tidak tampil di daftar.',
  feedType: 'EVENT',
  feedDt: '2020-03-08 08:00:00',
  userName: 'Ahmad Santoso',
  photos: ['https://example.com/a.webp'],
);

Widget _app(
  InformationItemEntity item, {
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool isSelectionMode = false,
  bool isSelected = false,
  bool isSelectable = true,
}) {
  return M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: InformationCard(
          item: item,
          onTap: onTap,
          onLongPress: onLongPress,
          isSelectionMode: isSelectionMode,
          isSelected: isSelected,
          isSelectable: isSelectable,
        ),
      ),
    ),
  );
}

void main() {
  group('InformationCard', () {
    testWidgets('shows category, author and date, title and one text line', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_item));

      expect(
        tester.widget<AppStatusPill>(find.byType(AppStatusPill)).label,
        'Acara',
      );
      expect(find.text('Ahmad Santoso · 8 Mar'), findsOneWidget);
      expect(find.text('Pengumuman Penting'), findsOneWidget);
      final body = tester.widget<Text>(find.textContaining('Baris pertama'));
      expect(body.maxLines, 1);
      // Photos and files belong to the detail screen.
      expect(find.byType(AppImageCollage), findsNothing);
      expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    });

    testWidgets('unknown category falls back to "Informasi Umum"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const InformationItemEntity(id: '2', title: 'X', photos: [])),
      );

      expect(
        tester.widget<AppStatusPill>(find.byType(AppStatusPill)).label,
        'Informasi Umum',
      );
      expect(find.byIcon(Icons.attach_file_rounded), findsNothing);
    });

    testWidgets('tap and long press reach the callbacks', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpWidget(
        _app(_item, onTap: () => taps++, onLongPress: () => longPresses++),
      );

      await tester.tap(find.text('Pengumuman Penting'));
      await tester.longPress(find.text('Pengumuman Penting'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(longPresses, 1);
    });

    testWidgets('semantic label names the post and its attachments', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_item, isSelectionMode: true, isSelected: true),
      );

      final card = tester.widget<AppCard>(find.byType(AppCard));
      expect(card.semanticLabel, contains('Informasi Pengumuman Penting'));
      expect(card.semanticLabel, contains('kategori Acara'));
      expect(card.semanticLabel, contains('1 foto terlampir'));
      expect(card.semanticLabel, contains('terpilih'));
    });

    testWidgets('selection mode shows the selection leading', (tester) async {
      await tester.pumpWidget(_app(_item, isSelectionMode: true));

      expect(find.byType(AppSelectionLeading), findsOneWidget);
    });

    testWidgets('an unselectable card is locked and dimmed', (tester) async {
      await tester.pumpWidget(
        _app(_item, isSelectionMode: true, isSelectable: false),
      );

      expect(find.byType(AppSelectionLeading), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        AppStateLayer.disabledOpacity,
      );
    });
  });
}
