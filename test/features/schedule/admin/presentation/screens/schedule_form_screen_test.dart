import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/managed_schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/schedule_entry.dart';
import 'package:kawalo_mobile/features/schedule/admin/domain/entities/shift_option_entity.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_cubit.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/cubit/schedule_form_state.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/screens/schedule_form_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockFormCubit extends MockCubit<ScheduleFormState>
    implements ScheduleFormCubit {}

const _members = [
  GroupMemberEntity(email: 'budi@x.id', name: 'Budi Santoso', role: 'GUARD'),
  GroupMemberEntity(email: 'siti@x.id', name: 'Siti Rahmawati'),
];
const _shifts = [
  ShiftOptionEntity(
    uid: 's1',
    name: 'Shift Pagi',
    startTime: '07:00',
    endTime: '15:00',
    color: '#3B82F6',
    locationName: 'Pos Utama',
  ),
];
const _ready = ScheduleFormState(
  status: ScheduleFormStatus.ready,
  members: _members,
  shifts: _shifts,
);

final _today = DateTime(2026, 11, 10);
final _day = DateTime(2026, 11, 11);

void main() {
  late _MockFormCubit cubit;
  late StreamController<ScheduleFormState> states;

  setUpAll(() {
    registerFallbackValue(<ScheduleEntry>[]);
  });

  setUp(() {
    cubit = _MockFormCubit();
    states = StreamController<ScheduleFormState>();
    addTearDown(states.close);
    whenListen(cubit, states.stream, initialState: _ready);
    when(
      () => cubit.submit(
        any(),
        editingId: any(named: 'editingId'),
        overwrite: any(named: 'overwrite'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    ManagedScheduleEntity? entry,
    bool canManage = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: BlocProvider<ScheduleFormCubit>.value(
          value: cubit,
          child: ScheduleFormScreen(
            today: _today,
            initialDate: _day,
            entry: entry,
            canManage: canManage,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> fillCreateForm(WidgetTester tester) async {
    await tester.tap(find.text('Pilih personil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Santoso').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih shift'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shift Pagi').last);
    await tester.pumpAndSettle();
  }

  testWidgets('saving an empty form shows what is missing and sends nothing', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Tambah jadwal'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppPageActions),
        matching: find.text('Simpan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Simpan')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.textContaining('Hapus'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Pilih personil.'), findsOneWidget);
    expect(find.text('Pilih shift.'), findsOneWidget);
    verifyNever(
      () => cubit.submit(
        any(),
        editingId: any(named: 'editingId'),
        overwrite: any(named: 'overwrite'),
      ),
    );
  });

  testWidgets('a filled form sends one entry for the chosen day', (
    tester,
  ) async {
    await pump(tester);
    await fillCreateForm(tester);

    expect(find.text('Akan dibuat 1 jadwal'), findsOneWidget);
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    final entries =
        verify(
              () => cubit.submit(
                captureAny(),
                editingId: any(named: 'editingId'),
                overwrite: any(named: 'overwrite'),
              ),
            ).captured.single
            as List<ScheduleEntry>;
    expect(entries, [
      ScheduleEntry(email: 'budi@x.id', shiftUid: 's1', date: _day),
    ]);
  });

  testWidgets('repeat shows the 92 day limit and the schedule count', (
    tester,
  ) async {
    await pump(tester);
    await fillCreateForm(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Harian'), findsOneWidget);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(
      find.textContaining('Maksimal 92 hari dari tanggal mulai'),
      findsOneWidget,
    );
    expect(find.text('Tanggal mulai *'), findsOneWidget);
  });

  testWidgets('editing prefills the row and saves with its id', (tester) async {
    final entry = ManagedScheduleEntity(
      id: '9',
      date: _day,
      email: 'budi@x.id',
      name: 'Budi Santoso',
      isMember: true,
      locked: false,
      shiftUid: 's1',
      shiftName: 'Shift Pagi',
    );
    await pump(tester, entry: entry);

    expect(find.text('Ubah jadwal'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Shift Pagi'), findsOneWidget);
    expect(find.text('Ulangi jadwal'), findsNothing);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    verify(
      () => cubit.submit(
        [ScheduleEntry(email: 'budi@x.id', shiftUid: 's1', date: _day)],
        editingId: '9',
        overwrite: any(named: 'overwrite'),
      ),
    ).called(1);
  });

  testWidgets('a locked row is read-only with its attendance', (tester) async {
    final entry = ManagedScheduleEntity(
      id: '9',
      date: DateTime(2026, 11, 9),
      email: 'siti@x.id',
      name: 'Siti Rahmawati',
      isMember: true,
      locked: true,
      shiftUid: 's1',
      shiftName: 'Shift Pagi',
      startTime: '07:00',
      endTime: '15:00',
      checkin: '07:04',
      lateMins: 4,
    );
    await pump(tester, entry: entry);

    expect(find.text('Detail jadwal'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Terkunci')),
      findsOneWidget,
    );
    expect(find.text('Simpan'), findsNothing);
    expect(find.byType(AppPageActions), findsNothing);
    expect(find.text('07:04'), findsOneWidget);
    expect(find.text('Terlambat 4 menit'), findsOneWidget);
    expect(find.text('Belum absen keluar'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });

  testWidgets(
    'the other-shift conflict is shown and only replaced after confirming',
    (tester) async {
      await pump(tester);
      await fillCreateForm(tester);
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      states.add(
        _ready.copyWith(
          status: ScheduleFormStatus.failed,
          message: 'Personil sudah punya jadwal shift lain pada tanggal ini.',
          canOverwrite: true,
        ),
      );
      await tester.pump();

      expect(
        find.text('Personil sudah punya jadwal shift lain pada tanggal ini.'),
        findsOneWidget,
      );
      expect(find.text('Lihat Jadwal Hari Itu'), findsOneWidget);

      await tester.ensureVisible(find.text('Ganti Jadwal Lama'));
      await tester.tap(find.text('Ganti Jadwal Lama'));
      await tester.pumpAndSettle();

      expect(find.text('Ganti jadwal lama?'), findsOneWidget);
      verifyNever(
        () => cubit.submit(
          any(),
          editingId: any(named: 'editingId'),
          overwrite: true,
        ),
      );

      await tester.tap(find.text('Ganti'));
      await tester.pumpAndSettle();

      verify(
        () => cubit.submit(
          any(),
          editingId: any(named: 'editingId'),
          overwrite: true,
        ),
      ).called(1);
    },
  );

  testWidgets('a failure without the conflict offers no overwrite', (
    tester,
  ) async {
    await pump(tester);
    states.add(
      _ready.copyWith(
        status: ScheduleFormStatus.failed,
        message:
            'Jadwal personil ini pada tanggal dan shift tersebut sudah ada.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('sudah ada.'), findsOneWidget);
    expect(find.text('Ganti Jadwal Lama'), findsNothing);
  });

  testWidgets('a saved form closes with the day and the summary', (
    tester,
  ) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<ScheduleFormCubit>.value(
                    value: cubit,
                    child: ScheduleFormScreen(today: _today, initialDate: _day),
                  ),
                ),
              );
            },
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await fillCreateForm(tester);

    states.add(
      _ready.copyWith(
        status: ScheduleFormStatus.saved,
        message: '12 jadwal dibuat.',
        result: const BulkScheduleResult(
          created: 12,
          replaced: 0,
          skipped: 0,
          skippedItems: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah jadwal'), findsNothing);
    expect(result, _day);
  });
}
