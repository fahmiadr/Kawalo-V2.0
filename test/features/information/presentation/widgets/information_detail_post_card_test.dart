import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_detail_post_card.dart';

void main() {
  group('InformationDetailPostCard Widget Tests', () {
    const feed = InformationItemEntity(
      id: 'post-1',
      photos: [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ],
      title: 'Patroli Lingkungan Blok A',
      text: 'Situasi aman terkendali tidak ada indikasi kejanggalan.',
      userName: 'Komandan Regu',
      userEmail: 'danru@kawalo.id',
      feedDt: '01 Okt 2026 14:00',
      feedType: 'GENERAL',
      groupName: 'Cluster Magnolia',
      eventLocation: 'Pos Utama',
      eventStartDt: '2026-10-01 13:00',
      eventEndDt: '2026-10-01 15:00',
      eventDuration: 2,
    );

    testWidgets(
        'renders user avatar, name, email, meta, title, text, and collage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: InformationDetailPostCard(item: feed),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header: Avatar, Name, Email
      expect(find.text('Komandan Regu'), findsOneWidget);
      expect(find.text('danru@kawalo.id'), findsOneWidget);

      // Meta: Category & Date
      expect(find.text('Informasi Umum'), findsOneWidget);
      expect(find.text('01 Okt 2026 14:00'), findsOneWidget);

      // Content: Title & Full text
      expect(find.text('Patroli Lingkungan Blok A'), findsOneWidget);
      expect(
        find.text('Situasi aman terkendali tidak ada indikasi kejanggalan.'),
        findsOneWidget,
      );

      // Media: Collage pattern
      expect(find.byType(AppImageCollage), findsOneWidget);

      // Explicitly excluded by design requirements:
      // NO unit/kawasan
      expect(find.text('Cluster Magnolia'), findsNothing);
      // NO jadwal acara
      expect(find.text('Jadwal Acara'), findsNothing);
    });
  });
}
