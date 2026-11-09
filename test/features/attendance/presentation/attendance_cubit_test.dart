import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/attendance_result.dart';
import 'package:kawalo_mobile/features/attendance/domain/value_objects/get_attendances_params.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepo;
  late AttendanceCubit cubit;

  setUp(() {
    mockRepo = MockAttendanceRepository();
    cubit = AttendanceCubit(repository: mockRepo);
  });

  tearDown(() {
    cubit.close();
  });

  const sampleItem = AttendanceItemEntity(
    id: '1',
    category: 'MASUK',
    diffMinutes: 0,
    userEmail: 'guard@kawalo.id',
    userName: 'Ahmad Santoso',
    attendanceDt: '2026-09-10T07:00:00.000Z',
    attendanceType: 'Absen Masuk shift pagi',
    locationName: 'Pos Gerbang Utama',
  );

  const sampleResult = AttendanceResult(items: [sampleItem]);

  const sampleCachedResult = AttendanceResult(
    items: [sampleItem],
    isFromCache: true,
  );

  setUpAll(() {
    registerFallbackValue(const GetAttendancesParams());
  });

  group('AttendanceCubit Tests', () {
    test('initial state is AttendanceInitial', () {
      expect(cubit.state, const AttendanceInitial());
    });

    blocTest<AttendanceCubit, AttendanceState>(
      'emits [AttendanceLoading, AttendanceLoaded] when fetch succeeds',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      act: (c) => c.fetchAttendances(),
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceLoaded>()
            .having((s) => s.attendances.length, 'attendances.length', 1)
            .having(
              (s) => s.attendances.first.userName,
              'userName',
              'Ahmad Santoso',
            )
            .having((s) => s.isFromCache, 'isFromCache', isFalse),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'emits [AttendanceLoading, AttendanceLoaded] with isFromCache true '
      'when serving cached fallback',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleCachedResult));
        return cubit;
      },
      act: (c) => c.fetchAttendances(),
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceLoaded>()
            .having((s) => s.attendances.length, 'attendances.length', 1)
            .having((s) => s.isFromCache, 'isFromCache', isTrue),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'emits AttendanceLoaded with empty items when cache returns empty on '
      'refresh and does not retain previous attendances',
      build: () {
        when(() => mockRepo.getAttendances(any())).thenAnswer(
          (_) async =>
              const Right(AttendanceResult(items: [], isFromCache: true)),
        );
        return cubit;
      },
      seed: () => const AttendanceLoaded(
        attendances: [sampleItem],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshAttendances(),
      expect: () => [
        isA<AttendanceLoaded>()
            .having((s) => s.attendances, 'attendances', isEmpty)
            .having((s) => s.isFromCache, 'isFromCache', isTrue),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'emits [AttendanceLoading, AttendanceError] when fetchAttendances fails',
      build: () {
        when(() => mockRepo.getAttendances(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal memuat data')),
        );
        return cubit;
      },
      act: (c) => c.fetchAttendances(),
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceError>().having(
          (s) => s.message,
          'message',
          'Gagal memuat data',
        ),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'retains cachedAttendances when refreshAttendances fails',
      build: () {
        when(() => mockRepo.getAttendances(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal memuat data')),
        );
        return cubit;
      },
      seed: () => const AttendanceLoaded(
        attendances: [sampleItem],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshAttendances(),
      expect: () => [
        isA<AttendanceError>()
            .having((s) => s.message, 'message', 'Gagal memuat data')
            .having(
              (s) => s.cachedAttendances.length,
              'cachedAttendances.length',
              1,
            ),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'clears cachedAttendances when fetchAttendances with new query fails',
      build: () {
        when(() => mockRepo.getAttendances(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal memuat data')),
        );
        return cubit;
      },
      seed: () => const AttendanceLoaded(
        attendances: [sampleItem],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.fetchAttendances(search: 'Budi'),
      expect: () => [
        isA<AttendanceError>()
            .having((s) => s.message, 'message', 'Gagal memuat data')
            .having((s) => s.cachedAttendances, 'cachedAttendances', isEmpty),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'refreshAttendances updates without emitting AttendanceLoading',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      seed: () => const AttendanceLoaded(
        attendances: [],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshAttendances(),
      expect: () => [
        isA<AttendanceLoaded>().having(
          (s) => s.attendances.length,
          'attendances.length',
          1,
        ),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'resetFilters fetches with default today period and null searchQuery',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      act: (c) => c.resetFilters(),
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceLoaded>()
            .having(
              (s) => s.filterPeriod,
              'filterPeriod',
              AppDateFilterPeriod.today,
            )
            .having((s) => s.searchQuery, 'searchQuery', isNull),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'fetchAttendances with empty search sets searchQuery to null and '
      'passes null to usecase',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      act: (c) => c.fetchAttendances(search: ''),
      verify: (_) {
        verify(
          () => mockRepo.getAttendances(
            any(
              that: isA<GetAttendancesParams>().having(
                (p) => p.search,
                'search',
                isNull,
              ),
            ),
          ),
        ).called(1);
      },
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceLoaded>().having(
          (s) => s.searchQuery,
          'searchQuery',
          isNull,
        ),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'setFilter passes sanitized ISO strings and updates AttendanceLoaded '
      'state with filter dates',
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      act: (c) => c.setFilter(
        const AppDateFilterResult(
          period: AppDateFilterPeriod.custom,
          startDateIso: '2026-09-01T00:00:00.000',
          endDateIso: '2026-09-10T23:59:59.000',
        ),
      ),
      verify: (_) {
        verify(
          () => mockRepo.getAttendances(
            any(
              that: isA<GetAttendancesParams>()
                  .having(
                    (p) => p.startDate,
                    'startDate',
                    '2026-09-01T00:00:00.000',
                  )
                  .having(
                    (p) => p.endDate,
                    'endDate',
                    '2026-09-10T23:59:59.000',
                  ),
            ),
          ),
        ).called(1);
      },
      expect: () => [
        const AttendanceLoading(),
        isA<AttendanceLoaded>()
            .having(
              (s) => s.filterPeriod,
              'filterPeriod',
              AppDateFilterPeriod.custom,
            )
            .having(
              (s) => s.startDateIso,
              'startDateIso',
              '2026-09-01T00:00:00.000',
            )
            .having(
              (s) => s.endDateIso,
              'endDateIso',
              '2026-09-10T23:59:59.000',
            )
            .having(
              (s) => s.hasActiveDateFilter,
              'hasActiveDateFilter',
              isTrue,
            ),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'resetDateFilter clears date filter while preserving search query',
      seed: () => AttendanceLoaded(
        attendances: const [sampleItem],
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
        searchQuery: 'satpam',
      ),
      build: () {
        when(
          () => mockRepo.getAttendances(any()),
        ).thenAnswer((_) async => const Right(sampleResult));
        return cubit;
      },
      act: (c) => c.resetDateFilter(),
      verify: (_) {
        verify(
          () => mockRepo.getAttendances(
            any(
              that: isA<GetAttendancesParams>().having(
                (p) => p.search,
                'search',
                'satpam',
              ),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as AttendanceLoaded;
        expect(loaded.searchQuery, 'satpam');
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
        expect(loaded.startDate, isNull);
        expect(loaded.endDate, isNull);
      },
    );

    test('refreshAttendances reuses in-flight background fetch with same key '
        'without duplicating request', () async {
      final backgroundCompleter =
          Completer<Either<Failure, AttendanceResult>>();

      var callCount = 0;
      when(() => mockRepo.getAttendances(any())).thenAnswer((_) {
        callCount++;
        return backgroundCompleter.future;
      });

      final backgroundFuture = cubit.fetchAttendances();
      expect(cubit.state, const AttendanceLoading());

      final refreshFuture = cubit.refreshAttendances();

      // Tidak memicu duplicate request ke server (di-reuse)
      expect(callCount, 1);

      backgroundCompleter.complete(const Right(sampleResult));
      await Future.wait([backgroundFuture, refreshFuture]);

      expect(cubit.state, isA<AttendanceLoaded>());
      final loaded = cubit.state as AttendanceLoaded;
      expect(loaded.attendances.length, 1);
      expect(loaded.isFromCache, isFalse);
      expect(callCount, 1);
    });

    test('fetchAttendances drops duplicate concurrent call with same key when '
        'not refresh', () async {
      final completer = Completer<Either<Failure, AttendanceResult>>();
      when(
        () => mockRepo.getAttendances(any()),
      ).thenAnswer((_) => completer.future);

      final firstFuture = cubit.fetchAttendances();
      final secondFuture = cubit.fetchAttendances();

      completer.complete(const Right(sampleResult));
      await Future.wait([firstFuture, secondFuture]);

      verify(() => mockRepo.getAttendances(any())).called(1);
    });

    test('fetchAttendances returns AppFetchResult.cancelled when cancelled '
        'and does not emit error state', () async {
      when(
        () => mockRepo.getAttendances(any()),
      ).thenAnswer((_) async => const Left(RequestCancelledFailure()));

      final result = await cubit.fetchAttendances();

      expect(result, AppFetchResult.cancelled);
      expect(cubit.state, const AttendanceLoading());
    });
  });
}
