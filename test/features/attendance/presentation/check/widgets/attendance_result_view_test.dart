import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_check_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/attendance_check_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/check/widgets/attendance_check_views.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_result_layout.dart';

AttendanceCheckResult _result({
  required bool checkIn,
  AttendanceCheckStatus status = AttendanceCheckStatus.onTime,
}) => AttendanceCheckResult(
  id: '1',
  isCheckIn: checkIn,
  attendanceAt: DateTime(2026, 11, 12, 7, 12),
  status: status,
  lateMinutes: 12,
  earlyLeaveMinutes: 40,
  shiftName: 'Shift Pagi',
  shiftTimeWindow: '07:00 - 15:00',
  locationName: 'Pos Utama / Lobby',
  distanceMeters: 38,
);

void main() {
  Future<void> pump(WidgetTester tester, AttendanceCheckResult result) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceResultView(
            result: result,
            onDone: () {},
            onOpenList: () {},
          ),
        ),
      );

  FaceResultTone tone(WidgetTester tester) =>
      tester.widget<FaceResultLayout>(find.byType(FaceResultLayout)).tone;

  AppStatusKind pill(WidgetTester tester) =>
      tester.widget<AppStatusPill>(find.byType(AppStatusPill)).kind;

  testWidgets('on-time check-in shows the time large and a green pill', (
    tester,
  ) async {
    await pump(tester, _result(checkIn: true));
    expect(find.text('Check-in berhasil'), findsOneWidget);
    expect(find.text('07.12'), findsOneWidget);
    expect(find.text('Tepat waktu'), findsOneWidget);
    expect(tone(tester), FaceResultTone.success);
    expect(pill(tester), AppStatusKind.ok);
  });

  testWidgets('shows the plain verified label, never a similarity', (
    tester,
  ) async {
    await pump(tester, _result(checkIn: true));
    expect(find.textContaining('Terverifikasi wajah'), findsOneWidget);
    expect(find.textContaining('Kemiripan'), findsNothing);
  });

  testWidgets('late check-in is recorded with an amber pill', (tester) async {
    await pump(
      tester,
      _result(checkIn: true, status: AttendanceCheckStatus.late),
    );
    expect(find.text('07.12'), findsOneWidget);
    expect(find.text('Terlambat 12 menit'), findsOneWidget);
    expect(pill(tester), AppStatusKind.bad);
  });

  testWidgets('early check-out is amber, on-time check-out green', (
    tester,
  ) async {
    await pump(
      tester,
      _result(checkIn: false, status: AttendanceCheckStatus.earlyLeave),
    );
    expect(find.text('Pulang 40 menit lebih cepat'), findsOneWidget);
    expect(pill(tester), AppStatusKind.bad);

    await pump(tester, _result(checkIn: false));
    expect(find.text('Sesuai jadwal'), findsOneWidget);
    expect(pill(tester), AppStatusKind.ok);
  });

  group('FaceNotMatchView', () {
    var retried = 0;
    var reported = 0;

    Future<void> pumpMismatch(
      WidgetTester tester, {
      required int failed,
      required bool manual,
    }) {
      retried = 0;
      reported = 0;
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: FaceNotMatchView(
            state: AttendanceCheckFaceNotMatch(
              message: 'Tidak cocok.',
              failedAttempts: failed,
              canRequestManual: manual,
            ),
            onRetry: () => retried++,
            onReport: () => reported++,
            onBack: () {},
          ),
        ),
      );
    }

    for (final failed in [1, 3, 5]) {
      testWidgets('after $failed failures Coba Lagi stays available', (
        tester,
      ) async {
        final manual = failed >= 3;
        await pumpMismatch(tester, failed: failed, manual: manual);

        expect(find.text('Coba Lagi'), findsOneWidget);
        expect(
          find.text('Lapor ke Admin'),
          findsAtLeastNWidgets(manual ? 1 : 0),
        );
        if (!manual) expect(find.text('Lapor ke Admin'), findsNothing);
        expect(find.textContaining('maksimal'), findsNothing);
        expect(find.textContaining('Batas'), findsNothing);
        expect(find.textContaining(' dari '), findsNothing);
        expect(find.textContaining('Kemiripan'), findsNothing);

        await tester.tap(find.text('Coba Lagi'));
        expect(retried, 1);
        expect(reported, 0);
      });
    }

    testWidgets('Lapor ke Admin opens the report when available', (
      tester,
    ) async {
      await pumpMismatch(tester, failed: 3, manual: true);
      await tester.tap(find.text('Lapor ke Admin'));
      expect(reported, 1);
      expect(retried, 0);
    });
  });

  test('only a check-out before the shift end counts as early', () {
    final slot = AttendanceSlot(
      date: DateTime(2026, 11, 12),
      shiftName: 'Shift Pagi',
      startTime: '07:00',
      endTime: '15:00',
    );
    final at1320 = DateTime(2026, 11, 12, 13, 20);
    expect(earlyCheckoutMinutes(slot, AttendanceAction.checkOut, at1320), 100);
    expect(
      earlyCheckoutMinutes(slot, AttendanceAction.checkIn, at1320),
      isNull,
    );
    expect(
      earlyCheckoutMinutes(
        slot,
        AttendanceAction.checkOut,
        DateTime(2026, 11, 12, 15, 3),
      ),
      isNull,
    );
  });
}
