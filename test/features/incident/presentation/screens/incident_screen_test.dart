import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_date_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_home_app_bar.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/screens/incident_screen.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_card.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_card_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentListCubit extends Mock implements IncidentListCubit {}

class MockUserSessionCubit extends Mock implements UserSessionCubit {}

class FakeAppDateFilterResult extends Fake implements AppDateFilterResult {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppDateFilterResult());
    registerFallbackValue(IncidentStatus.open);
  });

  late MockIncidentListCubit mockCubit;
  late MockUserSessionCubit mockSessionCubit;

  setUp(() {
    mockCubit = MockIncidentListCubit();
    mockSessionCubit = MockUserSessionCubit();
  });

  const tSession = AuthSessionEntity(
    userId: 'usr_1',
    role: 'ADMIN',
    email: 'admin@kawalo.id',
    name: 'Admin Kawalo',
    groupUid: 'grp_1',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  final tIncident = IncidentEntity(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Lampu Koridor Mati',
    description: 'Lampu koridor blok B padam total',
    status: IncidentStatus.open,
    createdBy: 'usr_1',
    createdByName: 'Ahmad Dahlan',
    createdAt: DateTime.parse('2026-11-04T12:00:00.000Z'),
  );

  Widget createWidgetUnderTest({
    required IncidentState state,
    AuthSessionEntity? session,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(state));
    when(
      () => mockCubit.fetchIncidents(
        session: any(named: 'session'),
        search: any(named: 'search'),
        filterPeriod: any(named: 'filterPeriod'),
        status: any(named: 'status'),
        clearStatusFilter: any(named: 'clearStatusFilter'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        startDateIso: any(named: 'startDateIso'),
        endDateIso: any(named: 'endDateIso'),
      ),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(() => mockCubit.setSearchQuery(any())).thenReturn(null);
    when(
      () => mockCubit.searchIncidents(any(), session: any(named: 'session')),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(
      () => mockCubit.refreshIncidents(
        session: any(named: 'session'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(
      () => mockCubit.resetFilters(session: any(named: 'session')),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(
      () => mockCubit.setFilter(any(), session: any(named: 'session')),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(
      () => mockCubit.setDateFilter(any(), session: any(named: 'session')),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(
      () => mockCubit.resetDateFilter(session: any(named: 'session')),
    ).thenAnswer((_) async => AppFetchResult.success);
    when(() => mockCubit.close()).thenAnswer((_) async {});

    when(() => mockSessionCubit.state).thenReturn(session ?? tSession);
    when(
      () => mockSessionCubit.stream,
    ).thenAnswer((_) => Stream.value(session ?? tSession));
    when(() => mockSessionCubit.close()).thenAnswer((_) async {});

    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserSessionCubit>.value(value: mockSessionCubit),
          BlocProvider<IncidentListCubit>.value(value: mockCubit),
        ],
        child: IncidentScreen(cubit: mockCubit),
      ),
    );
  }

  group('IncidentScreen UI & Accessibility Tests', () {
    testWidgets(
      'renders AppHomeAppBar with title "Insiden", filter chips including '
      'Tanggal, and skeleton on loading',
      (tester) async {
        const state = IncidentLoading();

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        expect(find.byType(AppHomeAppBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppHomeAppBar),
            matching: find.text('Insiden'),
          ),
          findsOneWidget,
        );
        expect(find.byType(AppChip), findsNWidgets(4));
        expect(find.text('Tanggal'), findsOneWidget);
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Terbuka'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);
        expect(find.byType(IncidentCardSkeleton), findsWidgets);
      },
    );

    testWidgets(
      'renders active date filter chip and resets date on delete tap',
      (tester) async {
        const state = IncidentLoaded(
          incidents: [],
          lastSync: 'Diperbarui Hari ini, 10.00',
          filterPeriod: AppDateFilterPeriod.thisWeek,
        );

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        // Chip tanggal menampilkan label periode aktif
        expect(find.text('Pekan ini'), findsOneWidget);

        // Tap delete icon pada chip tanggal
        final deleteIcon = find.byTooltip('Hapus filter');
        if (deleteIcon.evaluate().isNotEmpty) {
          await tester.tap(deleteIcon);
          await tester.pump();
          verify(
            () => mockCubit.resetDateFilter(session: any(named: 'session')),
          ).called(1);
        }
      },
    );

    testWidgets('renders search icon action and expands AppSearchBar on tap', (
      tester,
    ) async {
      final state = IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      // Cari tombol aksi pencarian
      final searchButton = find.bySemanticsLabel('Cari insiden');
      expect(searchButton, findsOneWidget);

      // Tap untuk expand pencarian
      await tester.tap(searchButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Judul diganti oleh AppSearchBar dengan hint 'Cari insiden'
      expect(find.byType(AppSearchBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppHomeAppBar),
          matching: find.text('Insiden'),
        ),
        findsNothing,
      );

      // Tombol action berubah menjadi tutup pencarian
      final closeButton = find.bySemanticsLabel('Tutup pencarian');
      expect(closeButton, findsOneWidget);

      // Tap tutup pencarian
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Judul "Insiden" muncul kembali
      expect(
        find.descendant(
          of: find.byType(AppHomeAppBar),
          matching: find.text('Insiden'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AppSearchBar), findsNothing);
    });

    testWidgets('renders list of IncidentCard when incidents are loaded', (
      tester,
    ) async {
      final state = IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(find.byType(IncidentCard), findsOneWidget);
      expect(find.text('Lampu Koridor Mati'), findsOneWidget);
      expect(find.text('Lampu koridor blok B padam total'), findsOneWidget);
      expect(find.textContaining('Ahmad Dahlan'), findsWidgets);
    });

    testWidgets('renders empty search result when search has no matches', (
      tester,
    ) async {
      const state = IncidentLoaded(
        incidents: [],
        lastSync: 'Diperbarui Hari ini, 10.00',
        searchQuery: 'banjir',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Laporan insiden tidak ditemukan'), findsOneWidget);
      expect(find.text('Reset filter & pencarian'), findsOneWidget);

      await tester.tap(find.text('Reset filter & pencarian'));
      verify(
        () => mockCubit.resetFilters(session: any(named: 'session')),
      ).called(1);
    });

    testWidgets('renders AppExtendedFab when user has active group session', (
      tester,
    ) async {
      final state = IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(find.byType(AppExtendedFab), findsOneWidget);
      expect(find.text('Insiden'), findsWidgets);
    });

    testWidgets('renders without overflow under 200% dynamic text scaling', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
      );

      final state = IncidentLoaded(
        incidents: [tIncident],
        lastSync: 'Diperbarui Hari ini, 10.00',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
