import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_cubit.dart';
import 'package:kawalo_mobile/features/attendance/stats/attendance_stats_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockStatsRepository extends Mock implements AttendanceStatsRepository {}

void main() {
  const stats = AttendanceStats(
    total: 120,
    checkIn: 62,
    checkOut: 58,
    late: 9,
    earlyLeave: 4,
  );
  late MockStatsRepository repository;

  setUp(() => repository = MockStatsRepository());

  blocTest<AttendanceStatsCubit, AttendanceStatsState>(
    'loads the summary',
    build: () {
      when(
        () => repository.getStats(from: '2026-11-01', to: '2026-11-12'),
      ).thenAnswer((_) async => const Right(stats));
      return AttendanceStatsCubit(repository: repository);
    },
    act: (cubit) => cubit.load(from: '2026-11-01', to: '2026-11-12'),
    expect: () => [
      const AttendanceStatsState(),
      const AttendanceStatsState(
        status: AttendanceStatsStatus.loaded,
        stats: stats,
      ),
    ],
  );

  blocTest<AttendanceStatsCubit, AttendanceStatsState>(
    'reports a failure so the card can hide itself',
    build: () {
      when(
        () => repository.getStats(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('gagal')));
      return AttendanceStatsCubit(repository: repository);
    },
    act: (cubit) => cubit.load(from: '2026-11-01', to: '2026-11-12'),
    expect: () => [
      const AttendanceStatsState(),
      const AttendanceStatsState(status: AttendanceStatsStatus.failure),
    ],
  );

  test('a slow answer for an old range never overwrites a newer one', () async {
    final slow = Completer<Either<Failure, AttendanceStats>>();
    when(
      () => repository.getStats(from: '2026-11-01', to: '2026-11-01'),
    ).thenAnswer((_) => slow.future);
    when(
      () => repository.getStats(from: '2026-11-02', to: '2026-11-02'),
    ).thenAnswer((_) async => const Right(stats));
    final cubit = AttendanceStatsCubit(repository: repository);

    final first = cubit.load(from: '2026-11-01', to: '2026-11-01');
    await cubit.load(from: '2026-11-02', to: '2026-11-02');
    slow.complete(
      const Right(
        AttendanceStats(
          total: 1,
          checkIn: 1,
          checkOut: 0,
          late: 0,
          earlyLeave: 0,
        ),
      ),
    );
    await first;

    expect(cubit.state.stats, stats);
    await cubit.close();
  });
}
