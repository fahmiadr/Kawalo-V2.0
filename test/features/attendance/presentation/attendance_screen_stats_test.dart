import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_cubit.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceCubit extends Mock implements AttendanceCubit {}

class MockStatsRepository extends Mock implements AttendanceStatsRepository {}

void main() {
  testWidgets('the summary is the first list item and loads for the range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final cubit = MockAttendanceCubit();
    when(() => cubit.state).thenReturn(
      const AttendanceLoaded(
        attendances: [
          AttendanceItemEntity(id: '1', category: 'MASUK', diffMinutes: 5),
        ],
        lastSync: 'Diperbarui Hari ini, 15.20',
        startDateIso: '2026-11-12T00:00:00.000',
        endDateIso: '2026-11-12T23:59:59.000',
      ),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => cubit.fetchAttendances(
        search: any(named: 'search'),
        filterPeriod: any(named: 'filterPeriod'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => AppFetchResult.success);
    final repository = MockStatsRepository();
    when(
      () => repository.getStats(from: '2026-11-12', to: '2026-11-12'),
    ).thenAnswer(
      (_) async => const Right(
        AttendanceStats(
          total: 31,
          checkIn: 20,
          checkOut: 11,
          late: 3,
          earlyLeave: 1,
        ),
      ),
    );
    final stats = AttendanceStatsCubit(repository: repository);
    addTearDown(stats.close);

    await tester.pumpWidget(
      M3EMaterialApp(
        data: AppTheme.m3eLight(),
        home: AttendanceScreen(cubit: cubit, statsCubit: stats),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => repository.getStats(from: '2026-11-12', to: '2026-11-12'),
    ).called(1);
    expect(find.text('Ringkasan absensi'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.byType(AttendanceCard), findsOneWidget);
  });
}
