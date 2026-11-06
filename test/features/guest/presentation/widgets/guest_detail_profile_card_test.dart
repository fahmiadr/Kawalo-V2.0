import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_profile_card.dart';

void main() {
  const sampleGuestNoPhoto = GuestItemEntity(
    id: 'guest_101',
    guestName: 'Bambang Sudarsono',
    guestNumber: 'B 2706 SBX',
    guestCategory: 'Taxi • KTP',
    guestDestination: 'JKN Veranda',
    guestToUserName: 'Wisnu Wijayadi',
    guestPurpose: 'Jemput Tamu',
    groupName: 'JKN Veranda',
    guestIdentity: '3171012345678901',
    guestIdentityType: 'KTP',
    guestAddress: 'Jl. Melati No. 45, Jakarta Selatan',
    qrUid: 'QR-GUEST-101',
  );

  const sampleGuestWithPhoto = GuestItemEntity(
    id: 'guest_202',
    guestName: 'Siti Rahmawati',
    guestNumber: 'B 1234 ABC',
    guestCategory: 'Tamu Pribadi',
    guestDestination: 'Blok C No. 12',
    guestToUserName: 'Ahmad Dahlan',
    guestPurpose: 'Kunjungan Keluarga',
    groupName: 'Cluster Asri',
    guestIdentity: '3201012345678902',
    guestIdentityType: 'SIM',
    guestPhoto: 'https://example.com/photos/guest_202.jpg',
    guestAddress: 'Jl. Mawar No. 10, Bogor',
    qrUid: 'QR-GUEST-202',
  );

  Widget buildTestCard(GuestItemEntity item) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GuestDetailProfileCard(item: item),
          ),
        ),
      ),
    );
  }

  group('GuestDetailProfileCard Widget Tests', () {
    testWidgets(
      'renders AppImagePlaceholder when guestPhoto is null or empty',
      (tester) async {
        await tester.pumpWidget(buildTestCard(sampleGuestNoPhoto));
        await tester.pumpAndSettle();

        expect(find.byType(AppImagePlaceholder), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(find.text('Bambang Sudarsono'), findsOneWidget);
        expect(find.text('No. tamu: B 2706 SBX'), findsOneWidget);
        expect(find.text('KTP: 3171012345678901'), findsOneWidget);
      },
    );

    testWidgets(
      'renders CachedNetworkImage and Hero when guestPhoto is valid URL',
      (tester) async {
        await tester.pumpWidget(buildTestCard(sampleGuestWithPhoto));
        await tester.pump();

        expect(find.byType(CachedNetworkImage), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Hero && widget.tag == 'guest_profile_guest_202_0',
          ),
          findsOneWidget,
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.label ==
                  'Lihat foto profil tamu Siti Rahmawati ukuran penuh',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'opens AppImageViewer when photo is tapped via AppTappable',
      (tester) async {
        await tester.pumpWidget(buildTestCard(sampleGuestWithPhoto));
        await tester.pump();

        final tappableFinder = find.byType(AppTappable);
        expect(tappableFinder, findsOneWidget);

        await tester.tap(tappableFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(AppImageViewer), findsOneWidget);
      },
    );
  });
}
