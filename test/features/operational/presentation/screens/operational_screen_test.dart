import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_offline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/operational/domain/entities/operational_item_entity.dart';
import 'package:kawalo_mobile/features/operational/domain/repositories/operational_repository.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/get_operationals_params.dart';
import 'package:kawalo_mobile/features/operational/domain/value_objects/operational_result.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_cubit.dart';
import 'package:kawalo_mobile/features/operational/presentation/cubit/operational_state.dart';
import 'package:kawalo_mobile/features/operational/presentation/screens/operational_screen.dart';
import 'package:kawalo_mobile/features/operational/presentation/widgets/operational_card.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationalRepository extends Mock implements OperationalRepository {}

class MockOperationalCubit extends Mock implements OperationalCubit {}

MockOperationalCubit createMockOperationalCubit({
  List<OperationalItemEntity>? operationals,
  String greeting = 'Diperbarui Hari ini, 15.20',
}) {
  final mockCubit = MockOperationalCubit();
  when(() => mockCubit.state).thenReturn(
    OperationalLoaded(
      operationals: operationals ?? const [],
      lastSync: greeting,
    ),
  );
  when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => mockCubit.currentGreeting).thenReturn(greeting);
  when(
    () => mockCubit.fetchOperationals(
      search: any(named: 'search'),
      filterPeriod: any(named: 'filterPeriod'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    () => mockCubit.refreshOperationals(search: any(named: 'search')),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    mockCubit.resetDateFilter,
  ).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetFilters).thenAnswer((_) async => AppFetchResult.success);
  return mockCubit;
}

void main() {
  final testWorkers = [
    const OperationalItemEntity(
      id: 'agus.security@kawalo.id_2026-09-29',
      userEmail: 'agus.security@kawalo.id',
      userName: 'Agus Setiawan',
      groupName: 'JKN Veranda',
      latestDuty: 'Patroli Lingkungan',
      latestState: 'Aktif',
      latestDutyDt: 'Hari ini, 08:30',
      latestStateDt: 'Hari ini, 08:35',
      totalActivities: 4,
      timeline: [
        DutyTimelineEntity(
          id: '101',
          journeyUid: 'JRN-001',
          duty: 'Patroli Lingkungan',
          state: 'Aktif',
          dutyDt: 'Hari ini, 08:30',
          stateDt: 'Hari ini, 08:35',
        ),
      ],
    ),
    const OperationalItemEntity(
      id: 'hendra.pratama@kawalo.id_2026-09-29',
      userEmail: 'hendra.pratama@kawalo.id',
      userName: 'Hendra Pratama',
      groupName: 'JKN Veranda',
      latestDuty: 'Jaga Pos Timur',
      latestState: 'Standby',
      latestDutyDt: 'Hari ini, 08:15',
      latestStateDt: 'Hari ini, 08:20',
      totalActivities: 3,
      timeline: [
        DutyTimelineEntity(
          id: '201',
          journeyUid: 'JRN-002',
          duty: 'Jaga Pos Timur',
          state: 'Standby',
          dutyDt: 'Hari ini, 08:15',
          stateDt: 'Hari ini, 08:20',
        ),
      ],
    ),
  ];

  Widget buildTestWidget({
    List<OperationalItemEntity>? initialWorkers,
    OperationalCubit? cubit,
    String? initialGreeting,
  }) {
    final effectiveCubit =
        cubit ??
        createMockOperationalCubit(
          operationals: initialWorkers ?? testWorkers,
          greeting: initialGreeting ?? 'Diperbarui Hari ini, 15.20',
        );
    return M3EMaterialApp(
      data: AppTheme.m3eLight(),
      home: OperationalScreen(cubit: effectiveCubit),
    );
  }

  group('OperationalScreen Tests', () {
    tearDown(AppSnackbar.hideCurrent);
    testWidgets(
      'renders AppHomeAppBar with back button, title, and search icon button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppHomeAppBar), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsOneWidget);
        expect(find.text('Aktifitas operasional'), findsOneWidget);
        expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Cari aktifitas operasional'),
          findsOneWidget,
        );

        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.text('Tanggal'), findsOneWidget);
        expect(find.bySemanticsLabel('Filter pencarian'), findsNothing);
      },
    );

    testWidgets(
      'toggles dynamically between Title and Search Bar via Top Bar trailing '
      'button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final searchToggleBtn = find.bySemanticsLabel(
          'Cari aktifitas operasional',
        );
        expect(searchToggleBtn, findsOneWidget);
        expect(find.text('Aktifitas operasional'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);

        // Tap search icon button -> opens search bar
        await tester.tap(searchToggleBtn);
        await tester.pumpAndSettle();

        expect(find.text('Aktifitas operasional'), findsNothing);
        expect(find.byType(AppSearchBar), findsOneWidget);
        expect(find.text('Cari aktifitas operasional'), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsOneWidget);

        final cancelToggleBtn = find.bySemanticsLabel('Tutup pencarian');
        expect(cancelToggleBtn, findsOneWidget);

        // Tap cancel icon button -> restores title
        await tester.tap(cancelToggleBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.text('Aktifitas operasional'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Cari aktifitas operasional'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders OperationalCard for each operational worker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(OperationalCard), findsNWidgets(2));
      expect(find.text('Agus Setiawan'), findsOneWidget);
      expect(find.text('Hendra Pratama'), findsOneWidget);
      expect(find.text('agus.security@kawalo.id'), findsOneWidget);
      expect(find.text('Patroli Lingkungan'), findsOneWidget);
    });

    testWidgets('filters list when user searches by worker name', (
      WidgetTester tester,
    ) async {
      registerFallbackValue(const GetOperationalsParams());
      final mockRepo = MockOperationalRepository();
      when(() => mockRepo.getOperationals(any())).thenAnswer((
        invocation,
      ) async {
        final params =
            invocation.positionalArguments.first as GetOperationalsParams;
        if (params.search?.toLowerCase() == 'agus') {
          return Right(OperationalResult(items: [testWorkers.first]));
        }
        return Right(OperationalResult(items: testWorkers));
      });

      final cubit = OperationalCubit(repository: mockRepo);

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: OperationalScreen(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppSearchBar), 'Agus');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(OperationalCard), findsOneWidget);
      expect(find.text('Agus Setiawan'), findsOneWidget);
      expect(find.text('Hendra Pratama'), findsNothing);
    });

    testWidgets('does not render SOS Extended FAB', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppExtendedFab), findsNothing);
      expect(find.text('SOS'), findsNothing);
    });

    testWidgets('renders AppRefreshIndicator with correct semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppRefreshIndicator), findsOneWidget);
    });

    testWidgets('renders Belum ada aktifitas operasional when list is empty '
        'without filter', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialWorkers: []));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada aktifitas operasional'), findsOneWidget);
      expect(find.text('Aktifitas operasional tidak ditemukan'), findsNothing);
    });

    testWidgets(
      'renders Tidak ada hasil ditemukan with reset button when search yields '
      'no match',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(() => mockRepo.getOperationals(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetOperationalsParams;
          if (params.search?.toLowerCase() == 'nonexistentworker') {
            return const Right(OperationalResult(items: []));
          }
          return Right(OperationalResult(items: testWorkers));
        });

        final cubit = OperationalCubit(repository: mockRepo);

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: OperationalScreen(cubit: cubit),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'NonExistentWorker');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(
          find.text('Aktifitas operasional tidak ditemukan'),
          findsOneWidget,
        );
        expect(find.text('Belum ada aktifitas operasional'), findsNothing);
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        // Tap reset
        await tester.tap(find.text('Reset filter & pencarian'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(OperationalCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'renders AppBottomOfflineBanner at the bottom when offline and reacts to '
      'online reconnect',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

        final connectivityCubit = ConnectivityCubit(
          autoStart: false,
          checkConnection: () async => false,
        )..setStatus(ConnectivityStatus.offline);

        final operationalCubit = OperationalCubit(repository: mockRepo);

        await tester.pumpWidget(
          BlocProvider<ConnectivityCubit>.value(
            value: connectivityCubit,
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              home: OperationalScreen(cubit: operationalCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsOneWidget,
        );

        // Verify reconnecting triggers auto-refresh and shows then hides banner
        connectivityCubit.setStatus(ConnectivityStatus.online);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Kembali online'), findsOneWidget);

        // Advance dwell duration & exit animation
        await tester.pump(const Duration(milliseconds: 2600));
        await tester.pumpAndSettle();

        expect(
          find.text('Mode offline — Menampilkan data tersimpan'),
          findsNothing,
        );
        expect(find.text('Kembali online'), findsNothing);
        final banner = tester.widget<AppBottomOfflineBanner>(
          find.byType(AppBottomOfflineBanner),
        );
        expect(banner.isOffline, isFalse);

        await operationalCubit.close();
        await connectivityCubit.close();
      },
    );

    testWidgets('focusing search bar does NOT trigger remote fetchWorkers', (
      WidgetTester tester,
    ) async {
      registerFallbackValue(const GetOperationalsParams());
      final mockRepo = MockOperationalRepository();
      when(
        () => mockRepo.getOperationals(any()),
      ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

      final operationalCubit = OperationalCubit(repository: mockRepo);

      await tester.pumpWidget(
        M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: OperationalScreen(cubit: operationalCubit),
        ),
      );
      await tester.pumpAndSettle();

      // Initial fetch on mount called once
      verify(() => mockRepo.getOperationals(any())).called(1);

      // Open search then tap/focus search bar without changing text
      await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Must NOT trigger another fetchWorkers call
      verifyNever(() => mockRepo.getOperationals(any()));

      // Entering text DOES trigger search after debounce
      await tester.enterText(find.byType(AppSearchBar), 'Agus');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(
        () => mockRepo.getOperationals(
          any(
            that: predicate<GetOperationalsParams>((p) => p.search == 'agus'),
          ),
        ),
      ).called(1);

      await operationalCubit.close();
    });

    testWidgets(
      'tapping Reset Filter & Pencarian triggers remote fetchWorkers exactly '
      'once',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

        final operationalCubit = OperationalCubit(repository: mockRepo);

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: OperationalScreen(cubit: operationalCubit),
          ),
        );
        await tester.pumpAndSettle();

        // Initial fetch on mount called once
        verify(() => mockRepo.getOperationals(any())).called(1);

        // Mock search returns empty so empty search state is displayed
        when(() => mockRepo.getOperationals(any())).thenAnswer(
          (_) async =>
              const Right(OperationalResult(items: <OperationalItemEntity>[])),
        );

        await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'TidakAda');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Search fetch was called once
        verify(() => mockRepo.getOperationals(any())).called(1);

        // Verify empty state button is visible
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

        // Tap "Reset filter & pencarian"
        await tester.tap(find.text('Reset filter & pencarian'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Check if called exactly 1 time
        verify(() => mockRepo.getOperationals(any())).called(1);

        await operationalCubit.close();
      },
    );

    testWidgets(
      'tapping Coba Lagi on error state preserves active search and filter',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(() => mockRepo.getOperationals(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Koneksi terputus')),
        );

        final operationalCubit = OperationalCubit(repository: mockRepo);

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: OperationalScreen(cubit: operationalCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1 initial fetch failed
        verify(() => mockRepo.getOperationals(any())).called(1);
        expect(find.text('Gagal memuat aktifitas operasional'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // Search with text 'Agus'
        await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(AppSearchBar), 'Agus');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Gagal memuat aktifitas operasional'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // When user taps 'Coba lagi', it should retry WITH search 'Agus'
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));
        clearInteractions(mockRepo);

        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        verify(
          () => mockRepo.getOperationals(
            any(
              that: predicate<GetOperationalsParams>((p) => p.search == 'Agus'),
            ),
          ),
        ).called(1);

        await operationalCubit.close();
      },
    );

    testWidgets(
      'preserves search and filter state when re-entering OperationalScreen '
      'with existing cubit state',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

        final operationalCubit = OperationalCubit(repository: mockRepo);

        // Fetch with search 'Agus' and filter 'thisWeek'
        await operationalCubit.fetchOperationals(
          search: 'Agus',
          filterPeriod: AppDateFilterPeriod.thisWeek,
        );

        // Mount OperationalScreen
        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: OperationalScreen(cubit: operationalCubit),
          ),
        );
        await tester.pumpAndSettle();

        // Expect search bar to contain 'Agus' and active filter chip to be
        // selected
        final searchBar = tester.widget<AppSearchBar>(
          find.byType(AppSearchBar),
        );
        expect(searchBar.controller?.text, 'Agus');
        final filterChip = tester.widget<AppChip>(find.byType(AppChip));
        expect(filterChip.selected, isTrue);

        await operationalCubit.close();
      },
    );

    testWidgets(
      'renders empty search state and offline bottom banner when offline and '
      'no results found',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(() => mockRepo.getOperationals(any())).thenAnswer(
          (_) async =>
              const Right(OperationalResult(items: [], isFromCache: true)),
        );

        final operationalCubit = OperationalCubit(repository: mockRepo);

        await operationalCubit.fetchOperationals(search: 'NonExistent');

        final connectivityCubit = ConnectivityCubit(
          autoStart: false,
          checkConnection: () async => false,
        )..setStatus(ConnectivityStatus.offline);

        await tester.pumpWidget(
          BlocProvider<ConnectivityCubit>.value(
            value: connectivityCubit,
            child: M3EMaterialApp(
              data: AppTheme.m3eLight(),
              home: OperationalScreen(cubit: operationalCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppBottomOfflineBanner), findsOneWidget);
        expect(
          find.text('Aktifitas operasional tidak ditemukan'),
          findsOneWidget,
        );
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        await operationalCubit.close();
        await connectivityCubit.close();
      },
    );

    testWidgets(
      'toggling search bar without query does not trigger fetchOperationals',
      (WidgetTester tester) async {
        registerFallbackValue(const GetOperationalsParams());
        final mockRepo = MockOperationalRepository();
        when(
          () => mockRepo.getOperationals(any()),
        ).thenAnswer((_) async => Right(OperationalResult(items: testWorkers)));

        final operationalCubit = OperationalCubit(repository: mockRepo);

        await tester.pumpWidget(
          M3EMaterialApp(
            data: AppTheme.m3eLight(),
            home: OperationalScreen(cubit: operationalCubit),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial postFrameCallback load calls fetchOperationals once
        verify(() => mockRepo.getOperationals(any())).called(1);

        // 2. Open search bar
        await tester.tap(find.bySemanticsLabel('Cari aktifitas operasional'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on open
        verifyNever(() => mockRepo.getOperationals(any()));

        // 3. Close search bar without entering text
        await tester.tap(find.bySemanticsLabel('Tutup pencarian'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on close when query was empty
        verifyNever(() => mockRepo.getOperationals(any()));

        await operationalCubit.close();
      },
    );
  });
}
