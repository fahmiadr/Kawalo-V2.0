import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: Scaffold(body: child),
    );
  }

  group('AttendanceCard Widget Tests', () {
    testWidgets('renders attendance details correctly', (tester) async {
      const item = AttendanceItemEntity(
        id: '1',
        category: 'MASUK',
        diffMinutes: 5,
        userEmail: 'guard.ahmad@kawalo.id',
        userName: 'Ahmad Santoso',
        attendanceDt: '2026-09-10T07:05:00.000Z',
        attendanceType: 'Absen Masuk shift pagi',
        locationName: 'Gerbang Utama Pos 1',
        shiftName: 'Shift Pagi',
        shiftTimeWindow: '07:00 - 15:00',
      );

      var tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AttendanceCard(item: item, onTap: () => tapped = true),
        ),
      );

      expect(find.text('Ahmad Santoso'), findsOneWidget);
      expect(find.text('guard.ahmad@kawalo.id'), findsOneWidget);
      expect(find.widgetWithText(AppTag, 'Masuk'), findsOneWidget);

      final diffTag = tester.widget<AppTag>(
        find.widgetWithText(AppTag, 'Terlambat 5 menit'),
      );
      expect(diffTag.variant, AppTagVariant.error);

      expect(find.text('Shift Pagi • 07:00 - 15:00'), findsOneWidget);
      expect(find.text('Gerbang Utama Pos 1'), findsOneWidget);

      await tester.tap(find.byType(AttendanceCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders on time pulang badge correctly', (tester) async {
      const item = AttendanceItemEntity(
        id: '2',
        category: 'PULANG',
        diffMinutes: 0,
        userEmail: 'guard.budi@kawalo.id',
        userName: 'Budi Pratama',
        attendanceDt: '2026-09-10T15:00:00.000Z',
        attendanceType: 'CHECK OUT',
        locationName: 'Pos 2',
        shiftName: 'Shift Siang',
      );

      await tester.pumpWidget(
        buildTestableWidget(const AttendanceCard(item: item)),
      );

      expect(find.text('Budi Pratama'), findsOneWidget);
      expect(find.widgetWithText(AppTag, 'Pulang'), findsOneWidget);

      final onTimeTag = tester.widget<AppTag>(
        find.widgetWithText(AppTag, 'Tepat waktu'),
      );
      expect(onTimeTag.variant, AppTagVariant.primary);
    });
  });
}
