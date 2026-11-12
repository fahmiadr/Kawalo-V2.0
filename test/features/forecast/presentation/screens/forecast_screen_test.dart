import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:kawalo_mobile/features/forecast/presentation/screens/forecast_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockForecastCubit extends MockCubit<ForecastState>
    implements ForecastCubit {}

AuthSessionEntity _session(String role) => AuthSessionEntity(
  userId: '1',
  email: 'a@x.id',
  name: 'Ani',
  role: role,
  allowAdmin: true,
  allowPatrol: false,
  allowMonPatrol: false,
);

const _options = ForecastOptions(
  shifts: [
    ForecastShift(
      uid: 's1',
      name: 'Pagi',
      startTime: '07:00',
      endTime: '15:00',
    ),
  ],
  people: [ForecastPerson(email: 'g@x.id', role: 'GUARD')],
);

final _config = ForecastConfig(
  startDate: DateTime(2026, 11, 12),
  endDate: DateTime(2026, 11, 18),
  quotas: const {'s1': 2},
  personnel: const ['g@x.id'],
);

ForecastPreview _preview() => const ForecastPreview(
  seed: 1,
  token: 't',
  existingCount: 2,
  deleteCount: 14,
  lockedCount: 3,
  plan: [],
  stats: ForecastStats(
    totalCreated: 22,
    totalDays: 7,
    totalPersonnel: 1,
    totalShifts: 1,
    totalCapacity: 14,
    perShift: [],
    perPersonnel: [],
    loadMin: 0,
    loadMax: 0,
    underStaffed: [],
    underStaffedTotal: 0,
  ),
);

void main() {
  late _MockForecastCubit cubit;

  setUp(() {
    cubit = _MockForecastCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.today).thenReturn(DateTime(2026, 11, 12));
    when(
      () => cubit.apply(overwriteConfirmed: any(named: 'overwriteConfirmed')),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    ForecastState state, {
    String role = 'ADMIN',
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<ForecastState>.empty(), initialState: state);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>(
        create: (_) => UserSessionCubit(_session(role)),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: ForecastScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('non-admin sees a notice and nothing is loaded', (tester) async {
    await pump(tester, const ForecastLoading(), role: 'GUARD');

    expect(find.text('Khusus admin'), findsOneWidget);
    verifyNever(() => cubit.load());
  });

  testWidgets('admin loads on open', (tester) async {
    await pump(tester, const ForecastLoading());

    verify(() => cubit.load()).called(1);
  });

  testWidgets('load error offers a retry', (tester) async {
    await pump(tester, const ForecastLoadError('Tidak ada koneksi.'));

    expect(find.text('Gagal memuat data forecast'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    verify(() => cubit.load()).called(2);
  });

  testWidgets('step 1 shows the sections of the form', (tester) async {
    await pump(tester, ForecastConfiguring(options: _options, config: _config));

    expect(find.text('Langkah 1 dari 2 · Pengaturan'), findsOneWidget);
    expect(find.text('Rentang tanggal'), findsOneWidget);
    expect(find.text('Shift dan kuota'), findsOneWidget);
    expect(find.text('1 dari 1 anggota dipilih'), findsOneWidget);
    expect(find.text('Lihat Pratinjau'), findsOneWidget);
  });

  testWidgets('a range over 92 days shows the error', (tester) async {
    await pump(
      tester,
      ForecastConfiguring(
        options: _options,
        config: _config.copyWith(endDate: DateTime(2027, 2, 20)),
      ),
    );

    expect(
      find.text('Rentang 101 hari. Maksimal 92 hari (sampai 11 Feb 2027).'),
      findsOneWidget,
    );
  });

  testWidgets('overwrite asks for confirmation naming the rows to delete', (
    tester,
  ) async {
    await pump(
      tester,
      ForecastPreviewReady(
        options: _options,
        config: _config.copyWith(fillMode: ForecastFillMode.overwrite),
        preview: _preview(),
      ),
    );

    await tester.tap(find.text('Simpan Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Timpa 14 jadwal?'), findsOneWidget);
    verifyNever(
      () => cubit.apply(overwriteConfirmed: any(named: 'overwriteConfirmed')),
    );

    await tester.tap(find.text('Timpa dan Simpan'));
    await tester.pumpAndSettle();

    verify(() => cubit.apply(overwriteConfirmed: true)).called(1);
  });

  testWidgets('empty mode saves without a dialog', (tester) async {
    await pump(
      tester,
      ForecastPreviewReady(
        options: _options,
        config: _config,
        preview: _preview(),
      ),
    );

    await tester.tap(find.text('Simpan Jadwal'));
    await tester.pump();

    verify(() => cubit.apply()).called(1);
  });

  testWidgets('stale preview explains and offers a new preview', (
    tester,
  ) async {
    await pump(
      tester,
      ForecastStale(
        options: _options,
        config: _config,
        message: 'Data jadwal berubah sejak pratinjau dibuat.',
      ),
    );

    expect(find.text('Pratinjau sudah kedaluwarsa'), findsOneWidget);
    expect(
      find.textContaining('Belum ada jadwal yang disimpan'),
      findsOneWidget,
    );
    expect(find.text('Buat Pratinjau Ulang'), findsOneWidget);
  });

  testWidgets('success shows created and deleted counts', (tester) async {
    await pump(
      tester,
      ForecastApplied(
        options: _options,
        config: _config,
        preview: _preview(),
        result: const ForecastResult(created: 22, deleted: 3),
      ),
    );

    expect(find.text('Jadwal berhasil dibuat'), findsOneWidget);
    expect(find.text('22 jadwal'), findsOneWidget);
    expect(find.text('3 jadwal'), findsWidgets);
  });
}
