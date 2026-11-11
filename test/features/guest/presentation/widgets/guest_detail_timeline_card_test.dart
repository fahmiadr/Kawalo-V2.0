import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/extensions/guest_ui_extension.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_detail_timeline_card.dart';

void main() {
  Widget build(GuestItemEntity item) => M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(body: GuestDetailTimelineCard(item: item)),
  );

  testWidgets('lists only Masuk and Keluar, even when acknowledged', (
    tester,
  ) async {
    const item = GuestItemEntity(
      id: '1',
      guestDt: '2026-09-28T08:14:00.000Z',
      guestAckDt: '2026-09-28T08:15:00.000Z',
    );
    await tester.pumpWidget(build(item));

    expect(find.text('Log aktivitas'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.text('Konfirmasi'), findsNothing);
    expect(find.text('Aktif'), findsOneWidget);
  });

  testWidgets('shows Selesai once the guest has left', (tester) async {
    const item = GuestItemEntity(
      id: '1',
      guestDt: '2026-09-28T08:14:00.000Z',
      guestOutDt: '2026-09-28T08:17:00.000Z',
    );
    await tester.pumpWidget(build(item));

    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Konfirmasi'), findsNothing);
    expect(find.text(item.displayExitTime), findsOneWidget);
  });
}
