import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_card.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_cubit.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockStatsRepository extends Mock implements AttendanceStatsRepository {}

void main() {
  Widget host(AttendanceStatsCubit cubit) => M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(
      body: AttendanceStatsCard(cubit: cubit, rangeLabel: 'Hari ini'),
    ),
  );

  testWidgets('shows the five counts for the range', (tester) async {
    final cubit = AttendanceStatsCubit(repository: MockStatsRepository())
      ..emit(
        const AttendanceStatsState(
          status: AttendanceStatsStatus.loaded,
          stats: AttendanceStats(
            total: 120,
            checkIn: 62,
            checkOut: 58,
            late: 9,
            earlyLeave: 4,
          ),
        ),
      );
    await tester.pumpWidget(host(cubit));

    expect(find.text('Ringkasan absensi'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);
    for (final text in ['120', '62', '58', '9', '4', 'Pulang cepat']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('lays the five counts out in two aligned rows', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final cubit = AttendanceStatsCubit(repository: MockStatsRepository())
      ..emit(
        const AttendanceStatsState(
          status: AttendanceStatsStatus.loaded,
          stats: AttendanceStats(
            total: 120,
            checkIn: 62,
            checkOut: 58,
            late: 9,
            earlyLeave: 4,
          ),
        ),
      );
    await tester.pumpWidget(host(cubit));

    final total = tester.getTopLeft(find.text('Total'));
    final late = tester.getTopLeft(find.text('Terlambat'));
    final early = tester.getTopLeft(find.text('Pulang cepat'));
    expect(late.dy, greaterThan(total.dy));
    expect(early.dy, late.dy);
    expect(late.dx, total.dx);
  });

  testWidgets('hides itself when the summary failed to load', (tester) async {
    final cubit = AttendanceStatsCubit(repository: MockStatsRepository())
      ..emit(const AttendanceStatsState(status: AttendanceStatsStatus.failure));
    await tester.pumpWidget(host(cubit));

    expect(find.text('Ringkasan absensi'), findsNothing);
  });
}
