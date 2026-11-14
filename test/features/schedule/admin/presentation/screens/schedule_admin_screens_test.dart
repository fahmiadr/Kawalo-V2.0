import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_admin_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_admin_day_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_admin_screen.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_admin_calendar.dart';
import 'package:mocktail/mocktail.dart';

class _MockCubit extends MockCubit<ScheduleAdminState>
    implements ScheduleAdminCubit {}

class _MockFormCubit extends MockCubit<ScheduleFormState>
    implements ScheduleFormCubit {}

AuthSessionEntity _session(String role) => AuthSessionEntity(
  userId: '1',
  email: 'admin@kawalo.id',
  name: 'Admin',
  role: role,
  allowAdmin: true,
  allowPatrol: false,
  allowMonPatrol: false,
);

final _today = DateTime(2026, 11, 10);

ManagedScheduleEntity _row(
  String id,
  String name, {
  DateTime? date,
  bool locked = false,
  String shift = 'a',
  String? checkin,
}) => ManagedScheduleEntity(
  id: id,
  date: date ?? DateTime(2026, 11, 11),
  email: '$id@x.id',
  name: name,
  isMember: true,
  locked: locked,
  shiftUid: shift,
  shiftName: shift == 'a' ? 'Shift Pagi' : 'Shift Siang',
  shiftColor: shift == 'a' ? '#3B82F6' : '#10B981',
  startTime: shift == 'a' ? '07:00' : '15:00',
  endTime: shift == 'a' ? '15:00' : '23:00',
  checkin: checkin,
);

void main() {
  late _MockCubit cubit;
  late _MockFormCubit formCubit;

  setUp(() {
    cubit = _MockCubit();
    formCubit = _MockFormCubit();
    when(
      () => formCubit.state,
    ).thenReturn(const ScheduleFormState(status: ScheduleFormStatus.ready));
    when(() => formCubit.loadOptions()).thenAnswer((_) async {});
    when(() => cubit.today).thenReturn(_today);
    when(
      () => cubit.load(silent: any(named: 'silent')),
    ).thenAnswer((_) async => true);
  });

  ScheduleAdminState state({
    ScheduleAdminStatus status = ScheduleAdminStatus.loaded,
    List<ManagedScheduleEntity> items = const [],
    DateTime? day,
    String? message,
  }) => ScheduleAdminState(
    month: DateTime(2026, 11),
    selectedDay: day ?? DateTime(2026, 11, 11),
    status: status,
    items: items,
    message: message,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child,
    ScheduleAdminState s, {
    String role = 'ADMIN',
  }) async {
    when(() => cubit.state).thenReturn(s);
    whenListen(
      cubit,
      const Stream<ScheduleAdminState>.empty(),
      initialState: s,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: BlocProvider<UserSessionCubit>.value(
          value: UserSessionCubit(_session(role)),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  group('ScheduleAdminCalendar', () {
    testWidgets('shows the month, a dot per shift and reports taps', (
      tester,
    ) async {
      DateTime? tapped;
      final s = state(
        items: [
          _row('1', 'A'),
          _row('2', 'B', shift: 'b'),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: ScheduleAdminCalendar(
              state: s,
              today: _today,
              onPreviousMonth: () {},
              onNextMonth: () {},
              onToday: () {},
              onSelectDay: (d) => tapped = d,
            ),
          ),
        ),
      );

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Sen'), findsOneWidget);
      // 6 weeks are not needed: 26 Oct - 6 Dec is five rows of seven.
      expect(
        find.bySemanticsLabel(RegExp(r'^11 November, 2 shift$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^10 November, hari ini, 0 shift$')),
        findsOneWidget,
      );

      await tester.tap(find.text('20'));
      expect(tapped, DateTime(2026, 11, 20));
    });
  });

  group('ScheduleAdminScreen', () {
    testWidgets('admin sees Tambah and Forecast, agenda grouped by shift', (
      tester,
    ) async {
      await pump(
        tester,
        ScheduleAdminScreen(cubit: cubit, onForecast: (_) async {}),
        state(
          items: [
            _row('1', 'Budi'),
            _row('2', 'Siti'),
            _row('3', 'Agus', shift: 'b'),
          ],
        ),
      );

      expect(find.text('Tambah Jadwal'), findsOneWidget);
      expect(find.text('Forecast Otomatis'), findsOneWidget);
      expect(find.text('Shift Pagi'), findsWidgets);
      expect(find.text('Budi, Siti'), findsOneWidget);
      expect(find.text('3 jadwal'), findsOneWidget);
      expect(find.text('Besok'), findsOneWidget);
    });

    testWidgets('a guard gets no action to change data', (tester) async {
      await pump(
        tester,
        ScheduleAdminScreen(cubit: cubit, onForecast: (_) async {}),
        state(items: [_row('1', 'Budi')]),
        role: 'GUARD',
      );

      expect(find.text('Tambah Jadwal'), findsNothing);
      expect(find.text('Forecast Otomatis'), findsNothing);
      expect(find.text('Budi'), findsOneWidget);
    });

    testWidgets('Forecast is hidden until the coordinator wires it', (
      tester,
    ) async {
      await pump(tester, ScheduleAdminScreen(cubit: cubit), state());

      expect(find.text('Tambah Jadwal'), findsOneWidget);
      expect(find.text('Forecast Otomatis'), findsNothing);
    });

    testWidgets('a past day says it is locked', (tester) async {
      await pump(
        tester,
        ScheduleAdminScreen(cubit: cubit),
        state(items: [_row('1', 'Budi')], day: DateTime(2026, 11, 9)),
      );

      expect(
        find.text('Hari lampau terkunci dan tidak bisa diubah.'),
        findsOneWidget,
      );
    });

    testWidgets('an empty month explains how to start', (tester) async {
      await pump(tester, ScheduleAdminScreen(cubit: cubit), state());

      expect(find.text('Belum ada jadwal di bulan ini'), findsOneWidget);
      expect(find.text('Tambah Jadwal'), findsOneWidget);
    });

    testWidgets('error shows the server message and retries', (tester) async {
      await pump(
        tester,
        ScheduleAdminScreen(cubit: cubit),
        state(status: ScheduleAdminStatus.error, message: 'Akses ditolak.'),
      );

      expect(find.text('Gagal memuat jadwal'), findsOneWidget);
      expect(find.text('Akses ditolak.'), findsOneWidget);
    });
  });

  group('ScheduleAdminDayScreen', () {
    final day = DateTime(2026, 11, 11);

    Future<void> pumpDay(
      WidgetTester tester, {
      bool canManage = true,
      DateTime? forDay,
    }) async {
      final d = forDay ?? day;
      await pump(
        tester,
        ScheduleAdminDayScreen(
          cubit: cubit,
          day: d,
          canManage: canManage,
          formCubitFactory: (_) => formCubit,
        ),
        state(
          day: d,
          items: [
            _row('1', 'Budi', date: d, locked: true, checkin: '06:52'),
            _row('2', 'Siti', date: d),
            _row('3', 'Agus', date: d, shift: 'b'),
          ],
        ),
      );
    }

    testWidgets('long-press selects an editable row and offers delete', (
      tester,
    ) async {
      await pumpDay(tester);

      await tester.longPress(find.text('Siti'));
      await tester.pump();

      expect(find.text('1 dipilih'), findsOneWidget);
      expect(find.text('Hapus (1)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppTopBar),
          matching: find.textContaining('Hapus'),
        ),
        findsNothing,
      );
    });

    testWidgets('a locked row cannot be selected and opens read-only', (
      tester,
    ) async {
      await pumpDay(tester);

      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Jadwal'), findsOneWidget);
      expect(find.text('Jadwal ini terkunci'), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets(
      'deleting names the person, shift and day, then calls the cubit',
      (tester) async {
        when(() => cubit.deleteMany(any())).thenAnswer(
          (_) async => const Right(
            DeleteSchedulesResult(deletedCount: 1, skippedCount: 0),
          ),
        );
        await pumpDay(tester);

        await tester.longPress(find.text('Siti'));
        await tester.pump();
        await tester.tap(find.text('Hapus (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus 1 jadwal?'), findsOneWidget);
        expect(
          find.textContaining('Siti tidak lagi dijadwalkan di Shift Pagi'),
          findsOneWidget,
        );
        verifyNever(() => cubit.deleteMany(any()));

        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        verify(() => cubit.deleteMany(['2'])).called(1);
      },
    );

    testWidgets('a non-admin opens read-only and gets no add action', (
      tester,
    ) async {
      await pumpDay(tester, canManage: false);

      expect(find.textContaining('Tambah ke'), findsNothing);
      await tester.tap(find.text('Siti'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Jadwal'), findsOneWidget);
      expect(
        find.text('Hanya admin yang dapat mengubah jadwal.'),
        findsOneWidget,
      );
    });

    testWidgets('a past day has no add action', (tester) async {
      await pumpDay(tester, forDay: DateTime(2026, 11, 9));

      expect(find.textContaining('Tambah ke'), findsNothing);
    });
  });
}
