import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_selection.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/app_image_collage.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';

Widget _buildCardTestApp(InformationItemEntity item, {VoidCallback? onTap}) {
  return MaterialApp(
    builder: (context, child) =>
        M3ETheme(data: AppTheme.m3eLight(), child: child!),
    home: Scaffold(
      body: SingleChildScrollView(
        child: InformationCard(item: item, onTap: onTap),
      ),
    ),
  );
}

void main() {
  group('InformationCard Tests', () {
    testWidgets(
      'renders basic information metadata without collage when no photos',
      (tester) async {
        const item = InformationItemEntity(
          id: 'info-1',
          title: 'Pengumuman Penting',
          text: 'Ini adalah deskripsi pengumuman penting.',
          feedType: 'GENERAL',
          feedDt: '2026-09-30 08:00:00',
          userName: 'Ahmad Santoso',
          photos: [],
        );

        await tester.pumpWidget(_buildCardTestApp(item));

        expect(find.text('Pengumuman Penting'), findsOneWidget);
        expect(find.text('Ahmad Santoso'), findsOneWidget);
        expect(find.text('Informasi Umum'), findsOneWidget);
        expect(find.byType(AppImageCollage), findsNothing);
      },
    );

    testWidgets('renders file attachment tag when hasFileAttachment is true', (
      tester,
    ) async {
      const item = InformationItemEntity(
        id: 'info-2',
        title: 'Laporan Kerusakan',
        feedType: 'INCIDENT',
        feedFile: 'dokumen_laporan.pdf',
        photos: [],
      );

      await tester.pumpWidget(_buildCardTestApp(item));

      expect(find.text('Insiden'), findsOneWidget);
      expect(find.text('Lampiran'), findsOneWidget);
    });

    testWidgets(
      'renders AppImageCollage when photos exist and opens AppImageViewer',
      (tester) async {
        final handle = tester.ensureSemantics();
        const item = InformationItemEntity(
          id: 'info-3',
          title: 'Foto Kegiatan Patroli',
          photos: [
            'https://example.com/p1.jpg',
            'https://example.com/p2.jpg',
            'https://example.com/p3.jpg',
          ],
        );

        await tester.pumpWidget(_buildCardTestApp(item));

        expect(find.byType(AppImageCollage), findsOneWidget);

        // Tap on image in collage to open AppImageViewer
        await tester.tap(find.bySemanticsLabel('Foto 1 dari 3'));
        await tester.pumpAndSettle();

        expect(find.byType(AppImageViewer), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);

        // Tap close button in viewer
        await tester.tap(find.byType(AppIconButton));
        await tester.pumpAndSettle();

        expect(find.byType(AppImageViewer), findsNothing);
        handle.dispose();
      },
    );

    testWidgets(
      'renders selected state with checkmark when isSelected is true',
      (tester) async {
        const item = InformationItemEntity(
          id: 'info-4',
          title: 'Laporan Ronda Malam',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: item,
                isSelectionMode: true,
                isSelected: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppSelectionLeading), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.check,
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('renders disabled locked state with 38% opacity '
        'when isSelectable is false', (tester) async {
      const item = InformationItemEntity(
        id: 'info-5',
        title: 'Laporan Petugas Lain',
        feedType: 'GENERAL',
        photos: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: const Scaffold(
            body: InformationCard(
              item: item,
              isSelectionMode: true,
              isSelectable: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, equals(0.38));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AppSvgIcon &&
              w.assetPath == KawaloVectors.squareLock01 &&
              w.size == 24,
        ),
        findsOneWidget,
      );
    });

    testWidgets('triggers onLongPress callback when long pressed', (
      tester,
    ) async {
      var longPressed = false;
      const item = InformationItemEntity(
        id: 'info-6',
        title: 'Postingan Uji Long Press',
        feedType: 'GENERAL',
        photos: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              M3ETheme(data: AppTheme.m3eLight(), child: child!),
          home: Scaffold(
            body: InformationCard(
              item: item,
              onLongPress: () {
                longPressed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Postingan Uji Long Press'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    testWidgets('does NOT render arrow chevron icon on InformationCard', (
      tester,
    ) async {
      const item = InformationItemEntity(
        id: 'info-7',
        title: 'Pengumuman Tanpa Arrow',
        feedType: 'GENERAL',
        userName: 'Ahmad Santoso',
        photos: [],
      );

      await tester.pumpWidget(_buildCardTestApp(item));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.arrowRight01,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'renders edit button with edit03 for ADMIN on any post and triggers '
      'onEdit',
      (tester) async {
        var editPressed = false;
        const adminSession = AuthSessionEntity(
          userId: 'admin-1',
          email: 'admin@kawalo.com',
          name: 'Administrator',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        const item = InformationItemEntity(
          id: 'info-8',
          title: 'Postingan Orang Lain',
          userEmail: 'guard@kawalo.com',
          userName: 'Guard One',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: Scaffold(
              body: InformationCard(
                item: item,
                currentUserSession: adminSession,
                onEdit: () {
                  editPressed = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.edit03,
          ),
          findsOneWidget,
        );

        await tester.tap(find.byType(AppIconButton));
        await tester.pumpAndSettle();

        expect(editPressed, isTrue);
      },
    );

    testWidgets(
      'renders edit button with edit03 for GUARD only on their own post',
      (tester) async {
        const guardSession = AuthSessionEntity(
          userId: 'guard-1',
          email: 'guard1@kawalo.com',
          name: 'Guard Satuan',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        const ownItem = InformationItemEntity(
          id: 'info-9',
          title: 'Postingan Saya Sendiri',
          userEmail: 'guard1@kawalo.com',
          userName: 'Guard Satuan',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: ownItem,
                currentUserSession: guardSession,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.edit03,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does NOT render edit button for GUARD on another author post',
      (tester) async {
        const guardSession = AuthSessionEntity(
          userId: 'guard-1',
          email: 'guard1@kawalo.com',
          name: 'Guard Satuan',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        const otherItem = InformationItemEntity(
          id: 'info-10',
          title: 'Postingan Guard Rekan',
          userEmail: 'guard2@kawalo.com',
          userName: 'Guard Dua',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: otherItem,
                currentUserSession: guardSession,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppSvgIcon &&
                (w.assetPath == KawaloVectors.edit03 ||
                    w.assetPath == KawaloVectors.editOff03),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'does NOT render edit button for non-authorized role or null session',
      (tester) async {
        const citizenSession = AuthSessionEntity(
          userId: 'citizen-1',
          email: 'citizen@kawalo.com',
          name: 'Warga Komplek',
          role: 'CITIZEN',
          allowAdmin: false,
          allowPatrol: false,
          allowMonPatrol: false,
        );

        const item = InformationItemEntity(
          id: 'info-11',
          title: 'Pengumuman Satpam',
          userEmail: 'guard1@kawalo.com',
          userName: 'Guard Satuan',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: item,
                currentUserSession: citizenSession,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppSvgIcon &&
                (w.assetPath == KawaloVectors.edit03 ||
                    w.assetPath == KawaloVectors.editOff03),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders editOff03 with disabled onPressed when isOffline is true',
      (tester) async {
        const adminSession = AuthSessionEntity(
          userId: 'admin-1',
          email: 'admin@kawalo.com',
          name: 'Administrator',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        const item = InformationItemEntity(
          id: 'info-12',
          title: 'Postingan Offline Test',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: item,
                currentUserSession: adminSession,
                isOffline: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.editOff03,
          ),
          findsOneWidget,
        );

        final iconButton = tester.widget<AppIconButton>(
          find.byType(AppIconButton),
        );
        expect(iconButton.onPressed, isNull);
      },
    );

    testWidgets(
      'does NOT render edit button in selection mode even if authorized',
      (tester) async {
        const adminSession = AuthSessionEntity(
          userId: 'admin-1',
          email: 'admin@kawalo.com',
          name: 'Administrator',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        const item = InformationItemEntity(
          id: 'info-13',
          title: 'Postingan Mode Seleksi',
          feedType: 'GENERAL',
          photos: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                M3ETheme(data: AppTheme.m3eLight(), child: child!),
            home: const Scaffold(
              body: InformationCard(
                item: item,
                currentUserSession: adminSession,
                isSelectionMode: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppSvgIcon &&
                (w.assetPath == KawaloVectors.edit03 ||
                    w.assetPath == KawaloVectors.editOff03),
          ),
          findsNothing,
        );
      },
    );
  });
}
