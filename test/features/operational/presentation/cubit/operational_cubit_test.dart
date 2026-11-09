import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationalRepository extends Mock implements OperationalRepository {}

void main() {
  late OperationalCubit cubit;
  late MockOperationalRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const GetOperationalsParams());
  });

  setUp(() {
    mockRepo = MockOperationalRepository();
    cubit = OperationalCubit(
      syncStorageService: SyncStorageService(),
      repository: mockRepo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tWorker = OperationalItemEntity(
    id: 'satpam1@kawalo.id_2026-09-09',
    userEmail: 'satpam1@kawalo.id',
    userName: 'Budi Santoso',
    groupName: 'JKN Veranda',
    latestDuty: 'Patroli Lingkungan',
    latestState: 'Aktif',
    latestDutyDt: '09 Sep 2026 08:30',
    latestStateDt: '09 Sep 2026 08:35',
    totalActivities: 1,
    timeline: [
      DutyTimelineEntity(
        id: '1',
        journeyUid: 'JRN-001',
        duty: 'Patroli Lingkungan',
        state: 'Aktif',
        dutyDt: '09 Sep 2026 08:30',
        stateDt: '09 Sep 2026 08:35',
      ),
    ],
  );
  const tWorkerList = [tWorker];
  const tResult = OperationalResult(items: tWorkerList);
  const tCachedResult = OperationalResult(
    items: tWorkerList,
    isFromCache: true,
  );

  test('initial state should be OperationalInitial', () {
    expect(cubit.state, const OperationalInitial());
    expect(cubit.currentGreeting, isEmpty);
  });

  test('initial state contains initialGreeting when provided', () {
    final customCubit = OperationalCubit(
      syncStorageService: SyncStorageService(),
      repository: mockRepo,
      initialGreeting: 'Diperbarui Hari ini, 15.20',
    );
    expect(
      customCubit.state,
      const OperationalInitial(lastSync: 'Diperbarui Hari ini, 15.20'),
    );
    expect(customCubit.currentGreeting, 'Diperbarui Hari ini, 15.20');
    customCubit.close();
  });

  group('fetchOperationals', () {
    blocTest<OperationalCubit, OperationalState>(
      'emits [OperationalLoading, OperationalLoaded] when successful',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchOperationals(),
      expect: () => [
        const OperationalLoading(),
        isA<OperationalLoaded>()
            .having((s) => s.operationals.length, 'operationals length', 1)
            .having(
              (s) => s.operationals.first.userName,
              'user name',
              'Budi Santoso',
            )
            .having(
              (s) => s.lastSync.startsWith('Diperbarui'),
              'has updated lastSync',
              isTrue,
            )
            .having((s) => s.isFromCache, 'isFromCache', false),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'emits [OperationalLoading, OperationalLoaded] with isFromCache true '
      'when serving cached fallback',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Right(tCachedResult));
        return cubit;
      },
      act: (cubit) => cubit.fetchOperationals(),
      expect: () => [
        const OperationalLoading(),
        isA<OperationalLoaded>()
            .having((s) => s.operationals.length, 'operationals length', 1)
            .having((s) => s.isFromCache, 'isFromCache', true),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'emits [OperationalLoading, OperationalError] when failure occurs',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      act: (cubit) => cubit.fetchOperationals(),
      expect: () => [
        const OperationalLoading(),
        isA<OperationalError>().having(
          (s) => s.message,
          'message',
          'Server Error',
        ),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'retains cachedOperationals when refreshOperationals fails',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      seed: () => const OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshOperationals(),
      expect: () => [
        isA<OperationalError>()
            .having((s) => s.message, 'message', 'Server Error')
            .having(
              (s) => s.cachedOperationals.length,
              'cachedOperationals.length',
              tWorkerList.length,
            ),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'emits OperationalLoaded with empty items when cache returns empty on '
      'refresh and does not retain previous operationals',
      seed: () => const OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      build: () {
        when(() => mockRepo.getOperationals(any())).thenAnswer(
          (_) async =>
              const Right(OperationalResult(items: [], isFromCache: true)),
        );
        return cubit;
      },
      act: (c) => c.refreshOperationals(),
      expect: () => [
        isA<OperationalLoaded>()
            .having((s) => s.operationals, 'operationals', isEmpty)
            .having((s) => s.isFromCache, 'isFromCache', isTrue),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'clears cachedOperationals when fetchOperationals with new query fails',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server Error')));
        return cubit;
      },
      seed: () => const OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.fetchOperationals(search: 'Hendra'),
      expect: () => [
        isA<OperationalError>()
            .having((s) => s.message, 'message', 'Server Error')
            .having((s) => s.cachedOperationals, 'cachedOperationals', isEmpty),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'emits OperationalError with empty cachedOperationals when custom filter '
      'fails',
      seed: () => OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
      ),
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Timeout')));
        return cubit;
      },
      act: (cubit) => cubit.fetchOperationals(
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
      ),
      expect: () => [
        isA<OperationalError>()
            .having((s) => s.message, 'message', 'Timeout')
            .having(
              (s) => s.filterPeriod,
              'filterPeriod',
              AppDateFilterPeriod.custom,
            )
            .having((s) => s.cachedOperationals, 'cachedOperationals', isEmpty),
      ],
    );

    blocTest<OperationalCubit, OperationalState>(
      'resetFilters clears search, date filter, and resets to today',
      seed: () => OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
        searchQuery: 'satpam',
      ),
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetFilters(),
      verify: (_) {
        verify(
          () => mockRepo.getOperationals(
            any(
              that: predicate<GetOperationalsParams>(
                (p) =>
                    p.search == null &&
                    p.startDate != null &&
                    p.endDate != null,
              ),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as OperationalLoaded;
        expect(loaded.searchQuery, isNull);
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
        expect(loaded.startDate, isNull);
        expect(loaded.endDate, isNull);
      },
    );

    blocTest<OperationalCubit, OperationalState>(
      'resetDateFilter clears date filter while preserving search query',
      seed: () => OperationalLoaded(
        operationals: tWorkerList,
        lastSync: 'Greeting',
        filterPeriod: AppDateFilterPeriod.custom,
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 9, 5),
        searchQuery: 'satpam',
      ),
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      act: (cubit) => cubit.resetDateFilter(),
      verify: (_) {
        verify(
          () => mockRepo.getOperationals(
            any(
              that: predicate<GetOperationalsParams>(
                (p) =>
                    p.search == 'satpam' &&
                    p.startDate != null &&
                    p.endDate != null,
              ),
            ),
          ),
        ).called(1);
        final loaded = cubit.state as OperationalLoaded;
        expect(loaded.searchQuery, 'satpam');
        expect(loaded.filterPeriod, AppDateFilterPeriod.today);
        expect(loaded.startDate, isNull);
        expect(loaded.endDate, isNull);
      },
    );
  });

  group('refreshOperationals', () {
    blocTest<OperationalCubit, OperationalState>(
      'updates without emitting OperationalLoading',
      build: () {
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => const Right(tResult));
        return cubit;
      },
      seed: () => const OperationalLoaded(
        operationals: [],
        lastSync: 'Diperbarui Hari ini, 15.20',
      ),
      act: (c) => c.refreshOperationals(),
      expect: () => [
        isA<OperationalLoaded>().having(
          (s) => s.operationals.length,
          'operationals.length',
          1,
        ),
      ],
    );
  });

  group('OperationalLoaded filter helper getters', () {
    test('hasActiveFilter bernilai true jika searchQuery tidak kosong', () {
      const stateDefault = OperationalLoaded(
        operationals: <OperationalItemEntity>[],
        lastSync: 'Waktu',
      );
      expect(stateDefault.hasActiveFilter, isFalse);

      final stateWithSearch = stateDefault.copyWith(searchQuery: 'satpam');
      expect(stateWithSearch.hasActiveFilter, isTrue);

      final stateWithEmptySearch = stateDefault.copyWith(searchQuery: '');
      expect(stateWithEmptySearch.hasActiveFilter, isFalse);
    });

    test(
      'hasActiveDateFilter bernilai true jika filter period bukan today atau '
      'ada custom date',
      () {
        const stateDefault = OperationalLoaded(
          operationals: <OperationalItemEntity>[],
          lastSync: 'Waktu',
        );
        expect(stateDefault.hasActiveDateFilter, isFalse);

        final stateWeek = stateDefault.copyWith(
          filterPeriod: AppDateFilterPeriod.thisWeek,
        );
        expect(stateWeek.hasActiveDateFilter, isTrue);

        final stateCustom = stateDefault.copyWith(
          filterPeriod: AppDateFilterPeriod.custom,
          startDate: DateTime(2026),
        );
        expect(stateCustom.hasActiveDateFilter, isTrue);
      },
    );

    test('hasActiveFilter mendeteksi kombinasi pencarian atau tanggal', () {
      const stateDefault = OperationalLoaded(
        operationals: <OperationalItemEntity>[],
        lastSync: 'Waktu',
      );
      expect(stateDefault.hasActiveFilter, isFalse);
      expect(
        stateDefault.copyWith(searchQuery: 'joko').hasActiveFilter,
        isTrue,
      );
      expect(
        stateDefault
            .copyWith(filterPeriod: AppDateFilterPeriod.thisMonth)
            .hasActiveFilter,
        isTrue,
      );
    });
  });

  group('RequestSequenceGuard in OperationalCubit', () {
    test('mengabaikan respons dari request lama yang datang terlambat '
        '(out-of-order)', () async {
      const workerA = OperationalResult(
        items: [
          OperationalItemEntity(
            id: 'satpam1@kawalo.id_2026-09-09',
            userEmail: 'satpam1@kawalo.id',
            userName: 'Worker A',
            groupName: 'JKN Veranda',
            latestDuty: 'Patroli Lingkungan',
            latestState: 'Aktif',
            latestDutyDt: '09 Sep 2026 08:30',
            latestStateDt: '09 Sep 2026 08:35',
            totalActivities: 1,
            timeline: [],
          ),
        ],
      );
      const workerB = OperationalResult(
        items: [
          OperationalItemEntity(
            id: 'satpam2@kawalo.id_2026-09-09',
            userEmail: 'satpam2@kawalo.id',
            userName: 'Worker B',
            groupName: 'JKN Veranda',
            latestDuty: 'Patroli Lingkungan',
            latestState: 'Aktif',
            latestDutyDt: '09 Sep 2026 08:30',
            latestStateDt: '09 Sep 2026 08:35',
            totalActivities: 1,
            timeline: [],
          ),
        ],
      );

      var firstCallCompleted = false;

      when(
        () => mockRepo.getOperationals(
          any(
            that: predicate<GetOperationalsParams>((p) => p.search == 'first'),
          ),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        firstCallCompleted = true;
        return const Right(workerA);
      });

      when(
        () => mockRepo.getOperationals(
          any(
            that: predicate<GetOperationalsParams>((p) => p.search == 'second'),
          ),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Right(workerB);
      });

      final futureFirst = cubit.fetchOperationals(search: 'first');
      final futureSecond = cubit.fetchOperationals(search: 'second');

      await Future.wait<void>([futureFirst, futureSecond]);

      expect(firstCallCompleted, isTrue);
      expect(cubit.state, isA<OperationalLoaded>());
      final loaded = cubit.state as OperationalLoaded;
      expect(loaded.searchQuery, 'second');
      expect(loaded.operationals.first.userName, 'Worker B');
    });
  });
}
