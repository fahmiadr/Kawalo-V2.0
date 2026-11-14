import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/storage/sync_storage_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_batch_guest/delete_batch_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/delete_guest/delete_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/get_guests_params.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/guest_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_screen.dart';
import 'package:kawalo_mobile/features/guest/presentation/widgets/guest_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockDeleteGuestUseCase extends Mock implements DeleteGuestUseCase {}

class MockDeleteBatchGuestUseCase extends Mock
    implements DeleteBatchGuestUseCase {}

class MockGuestCubit extends Mock implements GuestCubit {}

MockGuestCubit createMockGuestCubit({
  List<GuestItemEntity>? guests,
  String greeting = 'Diperbarui Hari ini, 15.20',
}) {
  final mockCubit = MockGuestCubit();
  when(() => mockCubit.state).thenReturn(
    GuestLoaded(
      guests: guests ?? GuestFixtures.defaultGuestEntities,
      lastSync: greeting,
    ),
  );
  when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => mockCubit.currentGreeting).thenReturn(greeting);
  when(
    () => mockCubit.fetchGuests(
      search: any(named: 'search'),
      filterPeriod: any(named: 'filterPeriod'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      creatorEmail: any(named: 'creatorEmail'),
      creatorName: any(named: 'creatorName'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    () => mockCubit.refreshGuests(search: any(named: 'search')),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    mockCubit.resetDateFilter,
  ).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetFilters).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.loadGroupMembers).thenAnswer((_) async => const Right([]));
  return mockCubit;
}

void main() {
  const defaultSession = AuthSessionEntity(
    userId: '1',
    email: 'guard@kawalo.id',
    name: 'Guard',
    role: 'GUARD',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  Widget buildTestWidget({
    List<GuestItemEntity>? initialGuests,
    String initialGreeting = 'Diperbarui Hari ini, 15.20',
    GuestCubit? cubit,
    AuthSessionEntity? session = defaultSession,
  }) {
    final effectiveCubit =
        cubit ??
        createMockGuestCubit(guests: initialGuests, greeting: initialGreeting);
    Widget app = M3EMaterialApp(
      localizationsDelegates: AppTheme.localizationsDelegates,
      data: AppTheme.m3eLight(),
      home: GuestScreen(cubit: effectiveCubit),
    );
    if (session != null) {
      app = BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session),
        child: app,
      );
    }
    return app;
  }

  group('GuestScreen Tests', () {
    tearDown(AppSnackbar.hideCurrent);
    testWidgets(
      'renders AppTopBar with back button, title, and search icon '
      'toggle button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppTopBar), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsNothing);
        expect(find.text('Buku Tamu'), findsOneWidget);
        expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari data tamu'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);
      },
    );

    testWidgets(
      'toggles dynamically between Title and Search Bar via Top Bar trailing '
      'button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final searchToggleBtn = find.bySemanticsLabel('Cari data tamu');
        expect(searchToggleBtn, findsOneWidget);
        expect(find.text('Buku Tamu'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);

        final titleRect = tester.getRect(find.text('Buku Tamu'));
        final backRect = tester.getRect(find.bySemanticsLabel('Kembali'));
        expect(titleRect.left - backRect.right, equals(8));

        // Tap search icon button -> opens search bar
        await tester.tap(searchToggleBtn);
        await tester.pumpAndSettle();

        expect(find.text('Buku Tamu'), findsNothing);
        expect(find.byType(AppSearchBar), findsOneWidget);
        expect(find.text('Cari data tamu'), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsNothing);

        final cancelToggleBtn = find.bySemanticsLabel('Tutup pencarian');
        expect(cancelToggleBtn, findsOneWidget);

        final searchBarRect = tester.getRect(find.byType(AppSearchBar));
        final cancelRect = tester.getRect(cancelToggleBtn);
        expect(searchBarRect.left, equals(titleRect.left));
        expect(searchBarRect.left - backRect.right, equals(8));
        expect(cancelRect.left - searchBarRect.right, equals(8));

        // Tap cancel icon button -> restores title
        await tester.tap(cancelToggleBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.text('Buku Tamu'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari data tamu'), findsOneWidget);
      },
    );

    testWidgets('renders on the redesign page background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, KawaloTones.light.background);
    });

    testWidgets('renders guest cards and allows filtering via search', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      registerFallbackValue(const GetGuestsParams());
      final mockGuestRepository = MockGuestRepository();
      when(() => mockGuestRepository.getGuests(any())).thenAnswer((
        invocation,
      ) async {
        final params = invocation.positionalArguments.first as GetGuestsParams;
        final search = params.search?.toLowerCase();
        if (search == null || search.isEmpty) {
          return const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          );
        }
        final filtered = GuestFixtures.defaultGuestEntities
            .where(
              (g) =>
                  (g.guestName?.toLowerCase().contains(search) ?? false) ||
                  (g.guestNumber?.toLowerCase().contains(search) ?? false),
            )
            .toList();
        return Right(GuestResult(items: filtered));
      });

      final cubit = GuestCubit(
        syncStorageService: SyncStorageService(),
        guestRepository: mockGuestRepository,
        deleteGuestUseCase: MockDeleteGuestUseCase(),
        deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
      );

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await tester.pumpAndSettle();

      // Memastikan kartu awal ter-render
      expect(find.byType(GuestCard), findsNWidgets(5));
      expect(find.text('Bambang Sudarsono'), findsOneWidget);
      expect(find.text('Reni Marsiti'), findsOneWidget);
      expect(find.text('Lestari Logistics'), findsOneWidget);
      expect(find.text('Blue Bird Taksi'), findsOneWidget);

      // Buka search bar via toggle button
      await tester.tap(find.bySemanticsLabel('Cari data tamu'));
      await tester.pumpAndSettle();

      // Memfilter daftar tamu dengan pencarian "Reni"
      await tester.enterText(find.byType(AppSearchBar), 'Reni');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Reni Marsiti'), findsOneWidget);
      expect(find.text('Bambang Sudarsono'), findsNothing);
      expect(find.byType(GuestCard), findsOneWidget);

      // Memfilter dengan pencarian yang tidak ada
      await tester.enterText(find.byType(AppSearchBar), 'Zzzzz');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(GuestCard), findsNothing);
      expect(find.text('Data tamu tidak ditemukan'), findsOneWidget);

      // Menutup pencarian via cancel button mengembalikan seluruh kartu
      await tester.tap(find.bySemanticsLabel('Tutup pencarian'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(GuestCard), findsNWidgets(5));

      await cubit.close();
    });

    testWidgets('tapping guest card opens standard M3E guest detail screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bambang Sudarsono'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestDetailScreen), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers data refresh indicator', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockCubit = createMockGuestCubit();
      await tester.pumpWidget(buildTestWidget(cubit: mockCubit));
      await tester.pumpAndSettle();

      expect(find.byType(AppRefreshIndicator), findsOneWidget);
      await tester.fling(
        find.text('Bambang Sudarsono'),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.refreshGuests(search: any(named: 'search')),
      ).called(1);
      expect(find.byType(GuestCard), findsNWidgets(5));
    });

    testWidgets('pull-to-refresh reactively updates greeting and guest data', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Diperbarui Hari ini, 15.20'), findsNothing);

      await tester.fling(
        find.text('Bambang Sudarsono'),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Data tamu berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets('renders the bottom "Catat Tamu" action instead of a FAB', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppExtendedFab), findsNothing);
      expect(find.widgetWithText(AppTaskButton, 'Catat Tamu'), findsOneWidget);
    });

    testWidgets(
      'renders safely under 200% dynamic text scaling without overflow',
      (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Buku Tamu'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari data tamu'), findsOneWidget);
        expect(find.byType(GuestCard), findsWidgets);
      },
    );

    testWidgets(
      'renders Belum ada data tamu when list is empty without filter',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(initialGuests: []));
        await tester.pumpAndSettle();

        expect(find.text('Belum ada tamu hari ini'), findsOneWidget);
        expect(find.text('Data tamu tidak ditemukan'), findsNothing);
      },
    );

    testWidgets(
      'renders Data tamu tidak ditemukan with reset button when search yields '
      'no match',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer((
          invocation,
        ) async {
          final params =
              invocation.positionalArguments.first as GetGuestsParams;
          if (params.search?.toLowerCase() == 'nonexistentguestxyz') {
            return const Right(GuestResult(items: []));
          }
          return const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          );
        });

        final cubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await tester.pumpWidget(buildTestWidget(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Cari data tamu'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(AppSearchBar),
          'NonExistentGuestXYZ',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Data tamu tidak ditemukan'), findsOneWidget);
        expect(find.text('Belum ada tamu hari ini'), findsNothing);
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        await tester.tap(find.text('Reset filter & pencarian'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(GuestCard), findsWidgets);

        await cubit.close();
      },
    );

    testWidgets(
      'renders the inline offline notice when offline and reacts to '
      'online reconnect',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );

        final connectivityCubit = ConnectivityCubit(
          autoStart: false,
          checkConnection: () async => false,
        )..setStatus(ConnectivityStatus.offline);

        final guestCubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await tester.pumpWidget(
          BlocProvider<ConnectivityCubit>.value(
            value: connectivityCubit,
            child: M3EMaterialApp(
              localizationsDelegates: AppTheme.localizationsDelegates,
              data: AppTheme.m3eLight(),
              home: GuestScreen(cubit: guestCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppInlineBanner), findsOneWidget);
        expect(
          find.textContaining('Anda offline. Menampilkan data tersimpan.'),
          findsOneWidget,
        );

        // Reconnecting triggers auto-refresh and removes the notice.
        connectivityCubit.setStatus(ConnectivityStatus.online);
        await tester.pumpAndSettle();

        expect(find.byType(AppInlineBanner), findsNothing);

        await guestCubit.close();
        await connectivityCubit.close();
      },
    );

    testWidgets('focusing search bar does NOT trigger remote fetchGuests', (
      WidgetTester tester,
    ) async {
      registerFallbackValue(const GetGuestsParams());
      final mockGuestRepository = MockGuestRepository();
      when(() => mockGuestRepository.getGuests(any())).thenAnswer(
        (_) async =>
            const Right(GuestResult(items: GuestFixtures.defaultGuestEntities)),
      );

      final guestCubit = GuestCubit(
        syncStorageService: SyncStorageService(),
        guestRepository: mockGuestRepository,
        deleteGuestUseCase: MockDeleteGuestUseCase(),
        deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
      );

      await tester.pumpWidget(
        M3EMaterialApp(
          localizationsDelegates: AppTheme.localizationsDelegates,
          data: AppTheme.m3eLight(),
          home: GuestScreen(cubit: guestCubit),
        ),
      );
      await tester.pumpAndSettle();

      // Initial fetch on mount called once
      verify(() => mockGuestRepository.getGuests(any())).called(1);

      // Open and tap/focus search bar without changing text
      await tester.tap(find.bySemanticsLabel('Cari data tamu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Must NOT trigger another fetchGuests call
      verifyNever(() => mockGuestRepository.getGuests(any()));

      // Entering text DOES trigger search after debounce
      await tester.enterText(find.byType(AppSearchBar), 'Bambang');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(
        () => mockGuestRepository.getGuests(
          any(that: predicate<GetGuestsParams>((p) => p.search == 'bambang')),
        ),
      ).called(1);

      await guestCubit.close();
    });

    testWidgets(
      'tapping Reset Filter & Pencarian triggers remote fetchGuests exactly '
      'once',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );

        final guestCubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await tester.pumpWidget(
          M3EMaterialApp(
            localizationsDelegates: AppTheme.localizationsDelegates,
            data: AppTheme.m3eLight(),
            home: GuestScreen(cubit: guestCubit),
          ),
        );
        await tester.pumpAndSettle();

        // Initial fetch on mount called once
        verify(() => mockGuestRepository.getGuests(any())).called(1);

        // Mock search returns empty so empty search state is displayed
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(GuestResult(items: <GuestItemEntity>[])),
        );

        await tester.tap(find.bySemanticsLabel('Cari data tamu'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'TidakAda');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Search fetch was called once
        verify(() => mockGuestRepository.getGuests(any())).called(1);

        // Verify empty state button is visible
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );

        // Tap "Reset filter & pencarian"
        await tester.tap(find.text('Reset filter & pencarian'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Check if called exactly 1 time
        verify(() => mockGuestRepository.getGuests(any())).called(1);

        await guestCubit.close();
      },
    );

    testWidgets(
      'tapping Coba lagi on error state preserves active search and filter',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Koneksi terputus')),
        );

        final guestCubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await tester.pumpWidget(
          M3EMaterialApp(
            localizationsDelegates: AppTheme.localizationsDelegates,
            data: AppTheme.m3eLight(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: GuestScreen(cubit: guestCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1 initial fetch failed
        verify(() => mockGuestRepository.getGuests(any())).called(1);
        expect(find.text('Gagal memuat data tamu'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // Open search and enter search text 'Bambang' in search bar
        await tester.tap(find.bySemanticsLabel('Cari data tamu'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(AppSearchBar), 'Bambang');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text('Gagal memuat data tamu'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // When user taps 'Coba lagi', it should retry WITH search 'Bambang'
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );
        clearInteractions(mockGuestRepository);

        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        verify(
          () => mockGuestRepository.getGuests(
            any(that: predicate<GetGuestsParams>((p) => p.search == 'Bambang')),
          ),
        ).called(1);

        await guestCubit.close();
      },
    );

    testWidgets(
      'preserves search and filter state when re-entering GuestScreen with '
      'existing cubit state',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );

        final guestCubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        // Fetch with search 'Bambang' and filter 'thisWeek'
        await guestCubit.fetchGuests(
          search: 'Bambang',
          filterPeriod: AppDateFilterPeriod.thisWeek,
        );

        // Mount GuestScreen
        await tester.pumpWidget(
          M3EMaterialApp(
            localizationsDelegates: AppTheme.localizationsDelegates,
            data: AppTheme.m3eLight(),
            home: GuestScreen(cubit: guestCubit),
          ),
        );
        await tester.pumpAndSettle();

        // Search is kept; a non-today period selects the "Semua" chip.
        final searchBar = tester.widget<AppSearchBar>(
          find.byType(AppSearchBar),
        );
        expect(searchBar.controller?.text, 'Bambang');
        final all = tester.widget<AppChip>(
          find.widgetWithText(AppChip, 'Semua'),
        );
        expect(all.selected, isTrue);

        await guestCubit.close();
      },
    );

    testWidgets(
      'toggling search bar without query does not trigger fetchGuests',
      (WidgetTester tester) async {
        registerFallbackValue(const GetGuestsParams());
        final mockGuestRepository = MockGuestRepository();
        when(() => mockGuestRepository.getGuests(any())).thenAnswer(
          (_) async => const Right(
            GuestResult(items: GuestFixtures.defaultGuestEntities),
          ),
        );

        final guestCubit = GuestCubit(
          syncStorageService: SyncStorageService(),
          guestRepository: mockGuestRepository,
          deleteGuestUseCase: MockDeleteGuestUseCase(),
          deleteBatchGuestUseCase: MockDeleteBatchGuestUseCase(),
        );

        await tester.pumpWidget(
          M3EMaterialApp(
            localizationsDelegates: AppTheme.localizationsDelegates,
            data: AppTheme.m3eLight(),
            home: GuestScreen(cubit: guestCubit),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial postFrameCallback load calls fetchGuests once
        verify(() => mockGuestRepository.getGuests(any())).called(1);

        // 2. Open search bar
        await tester.tap(find.bySemanticsLabel('Cari data tamu'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on open
        verifyNever(() => mockGuestRepository.getGuests(any()));

        // 3. Close search bar without entering text
        await tester.tap(find.bySemanticsLabel('Tutup pencarian'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on close when query was empty
        verifyNever(() => mockGuestRepository.getGuests(any()));

        await guestCubit.close();
      },
    );
  });
}
