import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/value_objects/delete_batch_result.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:kawalo_mobile/features/information/presentation/screens/information_screen.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_card.dart';
import 'package:mocktail/mocktail.dart';

class MockInformationCubit extends Mock implements InformationCubit {}

MockInformationCubit createMockInformationCubit({
  List<InformationItemEntity> items = const [],
  String greeting = 'Diperbarui Hari ini, 15.20',
  String? searchQuery,
}) {
  final mockCubit = MockInformationCubit();
  when(() => mockCubit.state).thenReturn(
    InformationLoaded(
      information: items,
      lastSync: greeting,
      searchQuery: searchQuery,
      isFromCache: true,
    ),
  );
  when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => mockCubit.currentGreeting).thenReturn(greeting);
  when(
    () => mockCubit.fetchInformation(
      search: any(named: 'search'),
      filterPeriod: any(named: 'filterPeriod'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
      authorEmail: any(named: 'authorEmail'),
      authorName: any(named: 'authorName'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    () => mockCubit.refreshInformation(search: any(named: 'search')),
  ).thenAnswer((_) async => AppFetchResult.success);
  when(
    mockCubit.resetDateFilter,
  ).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.resetFilters).thenAnswer((_) async => AppFetchResult.success);
  when(mockCubit.loadGroupMembers).thenAnswer((_) async => const Right([]));
  return mockCubit;
}

void main() {
  tearDown(AppSnackbar.hideCurrent);

  group('InformationScreen Tests', () {
    const dummyFeed = InformationItemEntity(
      id: '1',
      photos: [],
      title: 'Pemeriksaan Pos Jaga Utama',
      text: 'Seluruh personil telah bersiaga.',
      userEmail: 'satpam@kawalo.id',
      userName: 'Budi Santoso',
      feedDt: '09 Sep 2026 14:20',
      feedType: 'GENERAL',
      groupName: 'JKN Veranda',
      glat: -6.2,
      glong: 106.816666,
    );

    const dummyFeed2 = InformationItemEntity(
      id: '2',
      photos: [],
      title: 'Patroli Sektor Timur',
      text: 'Situasi aman terkendali.',
      userEmail: 'dani@kawalo.id',
      userName: 'Dani Pratama',
      feedDt: '09 Sep 2026 15:00',
      feedType: 'GENERAL',
      groupName: 'JKN Veranda',
      glat: -6.2,
      glong: 106.816666,
    );

    testWidgets(
      'renders AppHomeAppBar, AppRefreshIndicator and InformationCard',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(
              cubit: createMockInformationCubit(items: const [dummyFeed]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppHomeAppBar), findsOneWidget);
        expect(find.text('Pusat informasi'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari informasi'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.byType(AppRefreshIndicator), findsOneWidget);
        expect(find.byType(InformationCard), findsOneWidget);
        expect(find.text('Pemeriksaan Pos Jaga Utama'), findsOneWidget);
        expect(find.text('Budi Santoso'), findsOneWidget);
      },
    );

    testWidgets(
      'toggles dynamically between Title and Search Bar via Top Bar trailing '
      'button',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(
              cubit: createMockInformationCubit(items: const [dummyFeed]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final searchToggleBtn = find.bySemanticsLabel('Cari informasi');
        expect(searchToggleBtn, findsOneWidget);
        expect(find.text('Pusat informasi'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);

        // Tap search icon button -> opens search bar
        await tester.tap(searchToggleBtn);
        await tester.pumpAndSettle();

        expect(find.text('Pusat informasi'), findsNothing);
        expect(find.byType(AppSearchBar), findsOneWidget);
        expect(find.text('Cari informasi'), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsOneWidget);

        final cancelToggleBtn = find.bySemanticsLabel('Tutup pencarian');
        expect(cancelToggleBtn, findsOneWidget);

        // Tap cancel icon button -> restores title
        await tester.tap(cancelToggleBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.text('Pusat informasi'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari informasi'), findsOneWidget);
      },
    );

    testWidgets('renders AppEmptyState when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: InformationScreen(cubit: createMockInformationCubit()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppHomeAppBar), findsOneWidget);
      expect(find.text('Pusat informasi'), findsOneWidget);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum ada informasi'), findsOneWidget);
    });

    testWidgets('pull to refresh triggers callback', (tester) async {
      final mockCubit = createMockInformationCubit(items: const [dummyFeed]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: InformationScreen(cubit: mockCubit),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(
        () => mockCubit.refreshInformation(search: any(named: 'search')),
      ).called(1);
    });

    testWidgets('renders greeting when state.lastSync is present', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(
        const InformationLoaded(
          information: [dummyFeed],
          lastSync: 'Diperbarui Hari ini, 10.00',
          isFromCache: true,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
      when(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: InformationScreen(cubit: mockCubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diperbarui Hari ini, 10.00'), findsOneWidget);
    });

    testWidgets(
      'renders empty search result when search is active and list is empty',
      (tester) async {
        final mockCubit = MockInformationCubit();
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(
            information: [],
            lastSync: 'Diperbarui Hari ini, 10.00',
            searchQuery: 'pos pantau',
            isFromCache: true,
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Informasi tidak ditemukan'), findsOneWidget);
      },
    );

    testWidgets(
      'long press enters selection mode and shows delete action button',
      (tester) async {
        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(
                cubit: createMockInformationCubit(items: const [dummyFeed]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pusat informasi'), findsOneWidget);

        // Long press card to trigger selection
        await tester.longPress(find.text('Pemeriksaan Pos Jaga Utama'));
        await tester.pumpAndSettle();

        // Contextual selection app bar is visible
        expect(find.text('1'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Hapus informasi terpilih'),
          findsOneWidget,
        );

        // Tap cancel/close button to exit selection mode
        await tester.tap(find.bySemanticsLabel('Clear selection'));
        await tester.pumpAndSettle();

        expect(find.text('Pusat informasi'), findsOneWidget);
      },
    );

    testWidgets(
      'batch delete confirms dialog and calls cubit.deleteMultipleInformation',
      (tester) async {
        final mockCubit = MockInformationCubit();
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(information: [dummyFeed], lastSync: '10.00'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);
        when(
          () => mockCubit.deleteMultipleInformation(
            any(),
            session: any(named: 'session'),
          ),
        ).thenAnswer(
          (_) async => const Right(DeleteBatchResult(deletedCount: 1)),
        );

        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Long press card
        await tester.longPress(find.text('Pemeriksaan Pos Jaga Utama'));
        await tester.pumpAndSettle();

        // Tap delete button in app bar
        await tester.tap(find.bySemanticsLabel('Hapus informasi terpilih'));
        await tester.pumpAndSettle();

        // Confirmation dialog is shown
        expect(find.text('Hapus 1 informasi?'), findsOneWidget);

        // Tap confirm
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        verify(
          () => mockCubit.deleteMultipleInformation({
            '1',
          }, session: any(named: 'session')),
        ).called(1);
      },
    );

    testWidgets('GUARD cannot select post authored by another user', (
      tester,
    ) async {
      final sessionCubit = UserSessionCubit(
        const AuthSessionEntity(
          userId: 'guard-1',
          email: 'satpam.lain@kawalo.id',
          name: 'Satpam Lain',
          role: 'GUARD',
          allowAdmin: false,
          allowPatrol: true,
          allowMonPatrol: false,
        ),
      );

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: sessionCubit,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(
              cubit: createMockInformationCubit(items: const [dummyFeed]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press card authored by 'satpam@kawalo.id'
      await tester.longPress(find.text('Pemeriksaan Pos Jaga Utama'));
      await tester.pumpAndSettle();

      // Selection mode should NOT activate
      expect(find.text('Pusat informasi'), findsOneWidget);
      expect(
        find.text('Anda hanya dapat memilih informasi yang Anda buat.'),
        findsOneWidget,
      );
    });

    testWidgets('pull-to-refresh is disabled when in selection mode', (
      tester,
    ) async {
      final mockCubit = createMockInformationCubit(items: const [dummyFeed]);

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('Pemeriksaan Pos Jaga Utama'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Attempt fling to trigger refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // refreshInformation should NOT be triggered
      verifyNever(
        () => mockCubit.refreshInformation(search: any(named: 'search')),
      );
    });

    testWidgets(
      'renders filter chips for Tanggal and Dibuat oleh saya for GUARD role',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(
              cubit: createMockInformationCubit(items: const [dummyFeed]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppChip), findsNWidgets(2));
        expect(find.text('Tanggal').hitTestable(), findsOneWidget);
        expect(find.text('Dibuat oleh saya').hitTestable(), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Dibuat oleh saya calls cubit.changeAuthorFilter with user email',
      (tester) async {
        final mockCubit = MockInformationCubit();
        final sessionCubit = UserSessionCubit(
          const AuthSessionEntity(
            userId: 'budi-1',
            email: 'satpam@kawalo.id',
            name: 'Budi Santoso',
            role: 'GUARD',
            allowAdmin: false,
            allowPatrol: true,
            allowMonPatrol: false,
          ),
        );
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(information: [dummyFeed], lastSync: '10.00'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);
        when(
          () => mockCubit.changeAuthorFilter(
            email: any(named: 'email'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: sessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dibuat oleh saya').hitTestable().first);
        await tester.pumpAndSettle();

        verify(
          () => mockCubit.changeAuthorFilter(
            email: 'satpam@kawalo.id',
            name: 'Budi Santoso',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'selection is cleared when filter view switches per M3 guidelines',
      (tester) async {
        final sessionCubit = UserSessionCubit(
          const AuthSessionEntity(
            userId: 'budi-1',
            email: 'satpam@kawalo.id',
            name: 'Budi Santoso',
            role: 'GUARD',
            allowAdmin: false,
            allowPatrol: true,
            allowMonPatrol: false,
          ),
        );

        final streamController = StreamController<InformationState>.broadcast();
        final mockCubit = MockInformationCubit();
        var currentState = const InformationLoaded(
          information: [dummyFeed, dummyFeed2],
          lastSync: '10.00',
        );
        when(() => mockCubit.state).thenAnswer((_) => currentState);
        when(() => mockCubit.stream).thenAnswer((_) => streamController.stream);
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);
        when(
          () => mockCubit.changeAuthorFilter(
            email: any(named: 'email'),
            name: any(named: 'name'),
          ),
        ).thenAnswer((_) async {
          currentState = const InformationLoaded(
            information: [dummyFeed],
            lastSync: '10.00',
          );
          streamController.add(currentState);
          return AppFetchResult.success;
        });

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: sessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both items are present initially
        expect(find.text('Pemeriksaan Pos Jaga Utama'), findsOneWidget);
        expect(find.text('Patroli Sektor Timur'), findsOneWidget);

        // Long press item 1 to select
        await tester.longPress(find.text('Pemeriksaan Pos Jaga Utama'));
        await tester.pumpAndSettle();

        // 1 selected in app bar
        expect(find.text('1'), findsOneWidget);

        // Switch filter to 'Dibuat oleh saya'
        await tester.tap(find.text('Dibuat oleh saya').hitTestable().first);
        await tester.pumpAndSettle();

        // Contextual selection app bar is dismissed and standard app bar
        // is restored.
        expect(find.text('Pusat informasi'), findsOneWidget);
        expect(find.text('1'), findsNothing);

        // Only dummyFeed (satpam@kawalo.id) remains visible
        expect(find.text('Pemeriksaan Pos Jaga Utama'), findsOneWidget);
        expect(find.text('Patroli Sektor Timur'), findsNothing);

        await streamController.close();
      },
    );

    testWidgets('fetches information on initial load when isActive is true', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(
        const InformationLoaded(information: [dummyFeed], lastSync: '10.00'),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Siang');
      when(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);

      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(mockCubit.fetchInformation).called(1);
    });

    testWidgets('fetches information each time isActive transitions to true', (
      tester,
    ) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(
        const InformationLoaded(information: [dummyFeed], lastSync: '10.00'),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Siang');
      when(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);

      // Initial mount with isActive: false (seperti tab non-aktif)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: InformationScreen(cubit: mockCubit, isActive: false),
        ),
      );
      await tester.pumpAndSettle();

      // Tidak boleh melakukan fetch saat masih tidak aktif
      verifyNever(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );

      // Tab dibuka -> isActive menjadi true
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );

      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Melakukan fetch saat dibuka
      verify(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(1);

      // Tab beralih ke halaman lain -> isActive menjadi false
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: InformationScreen(cubit: mockCubit, isActive: false),
        ),
      );
      await tester.pumpAndSettle();

      // Tab dibuka kembali -> isActive menjadi true lagi
      await tester.pumpWidget(
        BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(adminSession),
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Melakukan fetch kembali setiap kali dibuka
      verify(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(1);
    });

    testWidgets('delete button is disabled in selection mode when offline', (
      tester,
    ) async {
      const sampleItem = InformationItemEntity(
        id: '1',
        photos: [],
        title: 'Info Judul',
        text: 'Info Deskripsi',
        userEmail: 'admin@kawalo.id',
        userName: 'Admin',
      );
      final mockCubit = createMockInformationCubit(
        items: const [sampleItem],
        greeting: '10:00',
      );
      const adminSession = AuthSessionEntity(
        userId: '1',
        email: 'admin@kawalo.id',
        name: 'Super Admin',
        role: 'ADMIN',
        allowAdmin: true,
        allowPatrol: true,
        allowMonPatrol: true,
      );
      final sessionCubit = UserSessionCubit(adminSession);

      final offlineCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserSessionCubit>.value(value: sessionCubit),
            BlocProvider<ConnectivityCubit>.value(value: offlineCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('Info Judul'));
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.byWidgetPredicate(
        (w) =>
            w is AppIconButton && w.semanticLabel == 'Hapus informasi terpilih',
      );
      expect(deleteBtnFinder, findsOneWidget);

      final iconButton = tester.widget<AppIconButton>(deleteBtnFinder);
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('does NOT trigger reactive refresh when coming back online if '
        'isActive is false', (tester) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(
        const InformationLoaded(information: [dummyFeed], lastSync: '10:00'),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
      when(
        () => mockCubit.refreshInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);

      final connectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: connectivityCubit,
          child: MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit, isActive: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Device transitions from offline to online while isActive is false
      connectivityCubit.setStatus(ConnectivityStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(
        () => mockCubit.refreshInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );

      await connectivityCubit.close();
    });

    testWidgets(
      'triggers reactive refresh when coming back online if isActive is true '
      'and current route',
      (tester) async {
        final mockCubit = MockInformationCubit();
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(information: [dummyFeed], lastSync: '10:00'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);
        when(
          () => mockCubit.refreshInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        final connectivityCubit = ConnectivityCubit(
          initialState: ConnectivityStatus.offline,
          autoStart: false,
        );

        await tester.pumpWidget(
          BlocProvider<ConnectivityCubit>.value(
            value: connectivityCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Device transitions from offline to online while isActive is true
        connectivityCubit.setStatus(ConnectivityStatus.online);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockCubit.refreshInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);

        await connectivityCubit.close();
      },
    );

    testWidgets('does NOT trigger reactive refresh when coming back online if '
        'another screen is on top', (tester) async {
      final mockCubit = MockInformationCubit();
      when(() => mockCubit.state).thenReturn(
        const InformationLoaded(information: [dummyFeed], lastSync: '10:00'),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
      when(
        () => mockCubit.fetchInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);
      when(
        () => mockCubit.refreshInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => AppFetchResult.success);

      final connectivityCubit = ConnectivityCubit(
        initialState: ConnectivityStatus.offline,
        autoStart: false,
      );

      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        BlocProvider<ConnectivityCubit>.value(
          value: connectivityCubit,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: AppTheme.lightThemeData(),
            home: InformationScreen(cubit: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push another screen on top of InformationScreen
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Detail Screen')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Screen'), findsOneWidget);

      // Device transitions from offline to online while InformationScreen
      // is not current route
      connectivityCubit.setStatus(ConnectivityStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(
        () => mockCubit.refreshInformation(
          search: any(named: 'search'),
          filterPeriod: any(named: 'filterPeriod'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );

      await connectivityCubit.close();
    });

    testWidgets(
      'toggling search bar without query does not trigger fetchInformation',
      (tester) async {
        final mockCubit = MockInformationCubit();
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(
            information: <InformationItemEntity>[],
            lastSync: 'Hari ini',
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        const adminSession = AuthSessionEntity(
          userId: '1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: UserSessionCubit(adminSession),
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial postFrameCallback load calls fetchInformation once
        verify(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);

        // 2. Open search bar
        await tester.tap(find.bySemanticsLabel('Cari informasi'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on open
        verifyNever(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );

        // 3. Close search bar without entering text
        await tester.tap(find.bySemanticsLabel('Tutup pencarian'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on close when query was empty
        verifyNever(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
      },
    );

    testWidgets(
      'calculates effective bottom padding correctly when keyboard opens',
      (tester) async {
        final mockCubit = MockInformationCubit();
        when(() => mockCubit.state).thenReturn(
          const InformationLoaded(
            information: <InformationItemEntity>[],
            lastSync: 'Hari ini',
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Selamat Pagi');
        when(
          () => mockCubit.fetchInformation(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        // Test with hasBottomNavigationBar: true
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: MediaQuery(
              data: const MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pump();

        final safeAreaFinder = find.ancestor(
          of: find.byType(Column),
          matching: find.byType(SafeArea),
        );
        final paddingWidget = tester.widget<Padding>(
          find.descendant(
            of: safeAreaFinder,
            matching: find.byWidgetPredicate(
              (w) => w is Padding && w.child is Column,
            ),
          ),
        );
        // 300 - (80 + 34) = 186.0
        expect((paddingWidget.padding as EdgeInsets).bottom, equals(186.0));

        // Test with hasBottomNavigationBar: false
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightThemeData(),
            home: MediaQuery(
              data: const MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
                viewPadding: EdgeInsets.only(bottom: 34),
              ),
              child: InformationScreen(
                cubit: mockCubit,
                hasBottomNavigationBar: false,
              ),
            ),
          ),
        );
        await tester.pump();

        final standalonePadding = tester.widget<Padding>(
          find.descendant(
            of: safeAreaFinder,
            matching: find.byWidgetPredicate(
              (w) => w is Padding && w.child is Column,
            ),
          ),
        );
        expect((standalonePadding.padding as EdgeInsets).bottom, equals(300.0));
      },
    );

    testWidgets(
      'renders Tambah informasi Extended FAB when user is ADMIN or GUARD, '
      'and no tambah button in top bar',
      (tester) async {
        final mockCubit = createMockInformationCubit(items: [dummyFeed]);
        const adminSession = AuthSessionEntity(
          userId: 'user-1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );
        final sessionCubit = UserSessionCubit(adminSession);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: sessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppExtendedFab), findsOneWidget);
        expect(find.text('Posting'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is AppIconButton && w.semanticLabel == 'Tambah informasi',
          ),
          findsNothing,
        );
        await sessionCubit.close();
      },
    );

    testWidgets(
      'Posting Extended FAB position remains stationary when keyboard appears',
      (tester) async {
        final mockCubit = createMockInformationCubit(items: [dummyFeed]);
        const adminSession = AuthSessionEntity(
          userId: 'user-1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );
        final sessionCubit = UserSessionCubit(adminSession);

        Widget buildTestScreen() {
          return BlocProvider<UserSessionCubit>.value(
            value: sessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: Scaffold(
                resizeToAvoidBottomInset: false,
                body: IndexedStack(
                  children: [InformationScreen(cubit: mockCubit)],
                ),
                bottomNavigationBar: const SizedBox(
                  height: 80,
                  child: Text('BottomNav'),
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();
        final fabInitialOffset = tester.getTopLeft(find.byType(AppExtendedFab));

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        final fabKeyboardOffset = tester.getTopLeft(
          find.byType(AppExtendedFab),
        );

        expect(fabKeyboardOffset.dy, equals(fabInitialOffset.dy));
        await sessionCubit.close();
      },
    );

    testWidgets(
      'renders Edit button on InformationCard when user can update item',
      (tester) async {
        final mockCubit = createMockInformationCubit(items: [dummyFeed]);
        const adminSession = AuthSessionEntity(
          userId: 'user-1',
          email: 'admin@kawalo.id',
          name: 'Super Admin',
          role: 'ADMIN',
          allowAdmin: true,
          allowPatrol: true,
          allowMonPatrol: true,
        );
        final sessionCubit = UserSessionCubit(adminSession);

        await tester.pumpWidget(
          BlocProvider<UserSessionCubit>.value(
            value: sessionCubit,
            child: MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: InformationScreen(cubit: mockCubit),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is AppIconButton &&
                w.semanticLabel != null &&
                w.semanticLabel!.startsWith('Edit informasi'),
          ),
          findsOneWidget,
        );
        await sessionCubit.close();
      },
    );
  });
}
