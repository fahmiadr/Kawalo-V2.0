import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_fab.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_inline_banner.dart';
import 'package:kawalo_mobile/core/widgets/app_search.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:kawalo_mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:kawalo_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_card.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceCubit extends Mock implements AttendanceCubit {}

MockAttendanceCubit createMockAttendanceCubit({
  List<AttendanceItemEntity> attendances = const [],
  String greeting = 'Diperbarui Hari ini, 15.20',
}) {
  final mockCubit = MockAttendanceCubit();
  when(
    () => mockCubit.state,
  ).thenReturn(AttendanceLoaded(attendances: attendances, lastSync: greeting));
  when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => mockCubit.currentGreeting).thenReturn(greeting);
  when(
    () => mockCubit.fetchAttendances(
      search: any(named: 'search'),
      filterPeriod: any(named: 'filterPeriod'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async => AppFetchResult.success);
  return mockCubit;
}

void main() {
  Widget buildTestableWidget(
    Widget child, {
    ConnectivityCubit? connectivityCubit,
  }) {
    final app = M3EMaterialApp(data: AppTheme.m3eLight(), home: child);
    if (connectivityCubit != null) {
      return BlocProvider<ConnectivityCubit>.value(
        value: connectivityCubit,
        child: app,
      );
    }
    return app;
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets(
      'renders app bar, title, search toggle, and empty state when empty',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(() => tester.view.reset());

        final mockCubit = createMockAttendanceCubit();
        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppTopBar), findsOneWidget);
        expect(find.text('Riwayat Absen'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari data absensi'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.byType(AppExtendedFab), findsNothing);
        expect(find.byType(TaskMessage), findsOneWidget);
        expect(find.text('Belum ada absensi'), findsOneWidget);
      },
    );

    testWidgets(
      'toggles dynamically between Title and Search Bar via Top Bar trailing '
      'button',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = createMockAttendanceCubit();
        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        final searchToggleBtn = find.bySemanticsLabel('Cari data absensi');
        expect(searchToggleBtn, findsOneWidget);
        expect(find.text('Riwayat Absen'), findsOneWidget);
        expect(find.byType(AppSearchBar), findsNothing);

        // Tap search icon button -> opens search bar
        await tester.tap(searchToggleBtn);
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Absen'), findsNothing);
        expect(find.byType(AppSearchBar), findsOneWidget);
        expect(find.text('Cari data absensi'), findsOneWidget);
        expect(find.text('Diperbarui Hari ini, 15.20'), findsNothing);

        final cancelToggleBtn = find.bySemanticsLabel('Tutup pencarian');
        expect(cancelToggleBtn, findsOneWidget);

        // Tap cancel icon button -> restores title
        await tester.tap(cancelToggleBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppSearchBar), findsNothing);
        expect(find.text('Riwayat Absen'), findsOneWidget);
        expect(find.bySemanticsLabel('Cari data absensi'), findsOneWidget);
      },
    );

    testWidgets('renders list of attendance cards when data is provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.reset());

      final nowIso = DateTime.now().toIso8601String();
      final attendances = [
        AttendanceItemEntity(
          id: '1',
          category: 'MASUK',
          diffMinutes: 5,
          userEmail: 'guard.ahmad@kawalo.id',
          userName: 'Ahmad Santoso',
          attendanceDt: nowIso,
          attendanceType: 'Absen Masuk shift pagi',
          locationName: 'Gerbang Utama Pos 1',
        ),
        AttendanceItemEntity(
          id: '2',
          category: 'PULANG',
          diffMinutes: 0,
          userEmail: 'guard.budi@kawalo.id',
          userName: 'Budi Pratama',
          attendanceDt: nowIso,
          attendanceType: 'CHECK OUT',
          locationName: 'Pos 2',
        ),
      ];

      final mockCubit = createMockAttendanceCubit(attendances: attendances);
      await tester.pumpWidget(
        buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceCard), findsNWidgets(2));
      expect(find.text('Ahmad Santoso'), findsOneWidget);
      expect(find.text('Budi Pratama'), findsOneWidget);
    });

    testWidgets(
      'typing only whitespace does not trigger fetch when initial query is '
      'empty',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(
          const AttendanceLoaded(attendances: [], lastSync: 'Hari ini'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        // Clear the invocation from initState postFrameCallback
        clearInteractions(mockCubit);

        // Open search and enter empty spaces
        await tester.tap(find.bySemanticsLabel('Cari data absensi'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), '   ');
        await tester.pump(const Duration(milliseconds: 500));

        // Must NOT call fetchAttendances
        verifyNever(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
      },
    );

    testWidgets(
      'clearing search text fetches with empty search to reset query',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(
          const AttendanceLoaded(attendances: [], lastSync: 'Hari ini'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        clearInteractions(mockCubit);

        // Open search and search for 'Budi'
        await tester.tap(find.bySemanticsLabel('Cari data absensi'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'Budi');
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockCubit.fetchAttendances(search: 'budi')).called(1);

        // Clear search to empty
        await tester.enterText(find.byType(AppSearchBar), '');
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockCubit.fetchAttendances(search: '')).called(1);
      },
    );

    testWidgets(
      'renders empty search state and offline notice when offline and '
      'no results found',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(
          const AttendanceLoaded(
            attendances: [],
            isFromCache: true,
            searchQuery: 'NonExistent',
            lastSync: 'Hari ini',
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        final connectivityCubit = ConnectivityCubit(
          autoStart: false,
          checkConnection: () async => false,
        )..setStatus(ConnectivityStatus.offline);

        await tester.pumpWidget(
          buildTestableWidget(
            AttendanceScreen(cubit: mockCubit),
            connectivityCubit: connectivityCubit,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppInlineBanner), findsOneWidget);
        expect(find.text('Data absensi tidak ditemukan'), findsOneWidget);
        expect(find.text('Reset filter & pencarian'), findsOneWidget);

        await connectivityCubit.close();
      },
    );

    testWidgets(
      'does not show snackbar when initial fetch succeeds or when request is '
      'cancelled',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(
          const AttendanceLoaded(attendances: [], lastSync: 'Hari ini'),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        // Tidak menampilkan snackbar "data berhasil dimuat"
        expect(find.text('Data absensi berhasil dimuat.'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);

        // Uji jika search mengembalikan cancelled
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.cancelled);

        // Open search then enter text
        await tester.tap(find.bySemanticsLabel('Cari data absensi'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(AppSearchBar), 'Ahmad');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Request cancelled tidak boleh menampilkan snackbar apapun
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'disables search button and filter button during initial loading',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(const AttendanceLoading());
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pump();

        // Search toggle button harus disabled saat initial loading
        final searchButton = tester.widget<AppIconButton>(
          find.byWidgetPredicate(
            (w) => w is AppIconButton && w.semanticLabel == 'Cari data absensi',
          ),
        );
        expect(searchButton.onPressed, isNull);

        // The range chips are disabled while the first page loads.
        final chips = tester.widget<TaskChoiceChips<String>>(
          find.byType(TaskChoiceChips<String>),
        );
        expect(chips.enabled, isFalse);
      },
    );

    testWidgets(
      'toggling search bar without query does not trigger fetchAttendances',
      (WidgetTester tester) async {
        final mockCubit = MockAttendanceCubit();
        when(() => mockCubit.state).thenReturn(
          const AttendanceLoaded(
            attendances: <AttendanceItemEntity>[],
            lastSync: 'Hari ini',
          ),
        );
        when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockCubit.currentGreeting).thenReturn('Hari ini');
        when(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => AppFetchResult.success);

        await tester.pumpWidget(
          buildTestableWidget(AttendanceScreen(cubit: mockCubit)),
        );
        await tester.pumpAndSettle();

        // 1. Initial postFrameCallback load calls fetchAttendances once
        verify(
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);

        // 2. Open search bar
        await tester.tap(find.bySemanticsLabel('Cari data absensi'));
        await tester.pumpAndSettle();

        // Verify no fetch triggered on open
        verifyNever(
          () => mockCubit.fetchAttendances(
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
          () => mockCubit.fetchAttendances(
            search: any(named: 'search'),
            filterPeriod: any(named: 'filterPeriod'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        );
      },
    );
  });
}
