import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incidents/get_incidents_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetIncidentsUseCase extends Mock implements GetIncidentsUseCase {}

class FakeGetIncidentsParams extends Fake implements GetIncidentsParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGetIncidentsParams());
  });

  late MockGetIncidentsUseCase mockGetIncidentsUseCase;
  late SyncStorageService syncStorageService;
  late IncidentListCubit cubit;

  setUp(() {
    mockGetIncidentsUseCase = MockGetIncidentsUseCase();
    syncStorageService = SyncStorageService();
    SyncStorageService.mockInstance = syncStorageService;
    cubit = IncidentListCubit(
      getIncidentsUseCase: mockGetIncidentsUseCase,
      syncStorageService: syncStorageService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tSession = AuthSessionEntity(
    userId: 'u1',
    email: 'guard@k.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
    groupUid: 'grp_1',
  );

  final tIncident = IncidentEntity(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Pintu Rusak',
    status: IncidentStatus.open,
    createdBy: 'u1',
    createdAt: DateTime(2026, 11, 6, 10),
  );

  final tIncident2 = IncidentEntity(
    id: 'inc_2',
    groupId: 'grp_1',
    title: 'Lampu Selesai Diperbaiki',
    status: IncidentStatus.resolved,
    createdBy: 'u1',
    createdAt: DateTime(2026, 11, 6, 11),
  );

  group('IncidentListCubit Initialization', () {
    test('initial state is IncidentInitial', () {
      expect(cubit.state, equals(const IncidentInitial()));
      expect(cubit.currentGreeting, isEmpty);
    });

    test('initial state contains initialGreeting when provided', () {
      final customCubit = IncidentListCubit(
        getIncidentsUseCase: mockGetIncidentsUseCase,
        initialGreeting: 'Diperbarui Hari ini, 15.20',
      );
      expect(
        customCubit.state,
        equals(const IncidentInitial(lastSync: 'Diperbarui Hari ini, 15.20')),
      );
      expect(customCubit.currentGreeting, 'Diperbarui Hari ini, 15.20');
      customCubit.close();
    });
  });

  group('fetchIncidents', () {
    blocTest<IncidentListCubit, IncidentState>(
      'emits [IncidentLoading, IncidentLoaded] on successful fetch from '
      'initial',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      act: (c) => c.fetchIncidents(session: tSession),
      expect: () => [
        isA<IncidentLoading>(),
        isA<IncidentLoaded>()
            .having((s) => s.incidents.length, 'incidents length', 1)
            .having((s) => s.hasMore, 'hasMore', false)
            .having(
              (s) => s.lastSync.startsWith('Diperbarui'),
              'has lastSync',
              isTrue,
            ),
      ],
      verify: (_) {
        verify(() => mockGetIncidentsUseCase(any())).called(1);
      },
    );

    blocTest<IncidentListCubit, IncidentState>(
      'emits [IncidentLoading, IncidentError] when initial fetch fails',
      build: () {
        when(() => mockGetIncidentsUseCase(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal memuat insiden')),
        );
        return cubit;
      },
      act: (c) => c.fetchIncidents(session: tSession),
      expect: () => [
        isA<IncidentLoading>(),
        isA<IncidentError>().having(
          (s) => s.message,
          'message',
          'Gagal memuat insiden',
        ),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'does not emit IncidentLoading when refreshing from IncidentLoaded',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident2]));
        return cubit;
      },
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.refreshIncidents(session: tSession),
      expect: () => [
        isA<IncidentLoaded>()
            .having((s) => s.incidents.length, 'incidents length', 1)
            .having((s) => s.incidents.first.id, 'id', 'inc_2'),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'emits IncidentError with cachedIncidents when refresh fails',
      build: () {
        when(() => mockGetIncidentsUseCase(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Koneksi terputus')),
        );
        return cubit;
      },
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.refreshIncidents(session: tSession),
      expect: () => [
        isA<IncidentError>()
            .having((s) => s.message, 'message', 'Koneksi terputus')
            .having(
              (s) => s.cachedIncidents.length,
              'cachedIncidents length',
              1,
            ),
      ],
    );
  });

  group('loadMore', () {
    blocTest<IncidentListCubit, IncidentState>(
      'appends newly fetched incidents when hasMore is true',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident2]));
        return cubit;
      },
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        filterPeriod: AppDateFilterPeriod.custom,
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.loadMore(session: tSession),
      expect: () => [
        isA<IncidentLoaded>().having(
          (s) => s.isLoadingMore,
          'loadingMore',
          true,
        ),
        isA<IncidentLoaded>()
            .having((s) => s.isLoadingMore, 'loadingMore', false)
            .having((s) => s.incidents.length, 'total count', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'does nothing when hasMore is false',
      build: () => cubit,
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        hasMore: false,
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.loadMore(session: tSession),
      expect: () => <IncidentState>[],
    );
  });

  group('Filtering and Searching', () {
    blocTest<IncidentListCubit, IncidentState>(
      'setFilter updates selectedFilter and refetches',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      act: (c) => c.setFilter(IncidentStatus.open, session: tSession),
      expect: () => [
        isA<IncidentLoading>(),
        isA<IncidentLoaded>()
            .having((s) => s.selectedFilter, 'filter', IncidentStatus.open)
            .having((s) => s.incidents.length, 'count', 1),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'setFilter null clears selectedFilter and refetches',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      seed: () => const IncidentLoaded(
        incidents: [],
        lastSync: 'Diperbarui',
        selectedFilter: IncidentStatus.open,
      ),
      act: (c) => c.setFilter(null, session: tSession),
      expect: () => [
        isA<IncidentLoaded>()
            .having((s) => s.selectedFilter, 'selectedFilter', isNull)
            .having((s) => s.incidents.length, 'count', 1),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'setDateFilter updates date fields and refetches',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      act: (c) {
        final filterResult = AppDateFilterResult.defaultFilter();
        c.setDateFilter(filterResult, session: tSession);
      },
      expect: () => [
        isA<IncidentLoading>(),
        isA<IncidentLoaded>()
            .having(
              (s) => s.filterPeriod,
              'period',
              AppDateFilterPeriod.today,
            )
            .having((s) => s.incidents.length, 'count', 1),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'resetDateFilter clears date fields and refetches',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      seed: () => IncidentLoaded(
        filterPeriod: AppDateFilterPeriod.thisWeek,
        startDate: DateTime(2026, 11),
        endDate: DateTime(2026, 11, 6),
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.resetDateFilter(session: tSession),
      expect: () => [
        isA<IncidentLoaded>()
            .having(
              (s) => s.filterPeriod,
              'period',
              AppDateFilterPeriod.today,
            )
            .having((s) => s.startDate, 'startDate', isNull)
            .having((s) => s.endDate, 'endDate', isNull),
      ],
    );

    test('searchIncidents returns AppFetchResult.success and updates query',
        () async {
      when(() => mockGetIncidentsUseCase(any()))
          .thenAnswer((_) async => Right([tIncident]));

      final result = await cubit.searchIncidents('pintu', session: tSession);
      expect(result, equals(AppFetchResult.success));
      expect(cubit.state.searchQuery, equals('pintu'));
    });

    blocTest<IncidentListCubit, IncidentState>(
      'resetFilters clears status, search, and date filters',
      build: () {
        when(() => mockGetIncidentsUseCase(any()))
            .thenAnswer((_) async => Right([tIncident]));
        return cubit;
      },
      seed: () => IncidentLoaded(
        selectedFilter: IncidentStatus.open,
        searchQuery: 'pintu',
        filterPeriod: AppDateFilterPeriod.thisMonth,
        startDate: DateTime(2026, 11),
        endDate: DateTime(2026, 11, 6),
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.resetFilters(session: tSession),
      expect: () => [
        isA<IncidentLoaded>()
            .having((s) => s.selectedFilter, 'selectedFilter', isNull)
            .having((s) => s.searchQuery, 'searchQuery', isNull)
            .having((s) => s.startDate, 'startDate', isNull)
            .having((s) => s.endDate, 'endDate', isNull),
      ],
    );
  });

  group('Local Mutations', () {
    blocTest<IncidentListCubit, IncidentState>(
      'onIncidentCreated prepends new incident to the list in IncidentLoaded',
      build: () => cubit,
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.onIncidentCreated(tIncident2),
      expect: () => [
        isA<IncidentLoaded>()
            .having((s) => s.incidents.length, 'length', 2)
            .having((s) => s.incidents.first.id, 'first id', 'inc_2'),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'onIncidentUpdated replaces existing incident in the list',
      build: () => cubit,
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) {
        final updated = tIncident.copyWith(title: 'Pintu Selesai Diperbaiki');
        c.onIncidentUpdated(updated);
      },
      expect: () => [
        isA<IncidentLoaded>()
            .having((s) => s.incidents.length, 'length', 1)
            .having(
              (s) => s.incidents.first.title,
              'title',
              'Pintu Selesai Diperbaiki',
            ),
      ],
    );

    blocTest<IncidentListCubit, IncidentState>(
      'onIncidentDeleted removes item from list in IncidentLoaded',
      build: () => cubit,
      seed: () => IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      ),
      act: (c) => c.onIncidentDeleted('inc_1'),
      expect: () => [
        isA<IncidentLoaded>().having((s) => s.incidents, 'incidents', isEmpty),
      ],
    );
  });
}
