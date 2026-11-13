import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_list_state.dart';
import 'package:kawalo_mobile/features/shift/presentation/screens/shift_form_dialog.dart';
import 'package:kawalo_mobile/features/shift/presentation/screens/shift_screen.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_card.dart';
import 'package:kawalo_mobile/features/shift/presentation/widgets/shift_card_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class _MockListCubit extends MockCubit<ShiftListState>
    implements ShiftListCubit {}

class _MockRepository extends Mock implements ShiftRepository {}

class _FakeInput extends Fake implements ShiftInput {}

const _pagi = ShiftEntity(
  uid: 'a',
  name: 'Shift Pagi',
  startTime: ShiftClock(7, 0),
  endTime: ShiftClock(15, 0),
  color: '#F2A900',
);

const _malam = ShiftEntity(
  uid: 'b',
  name: 'Shift Malam',
  startTime: ShiftClock(23, 0),
  endTime: ShiftClock(7, 0),
  color: '#546E7A',
);

void main() {
  group('ShiftScreen', () {
    late _MockListCubit cubit;

    setUp(() {
      cubit = _MockListCubit();
      when(
        () => cubit.fetch(silent: any(named: 'silent')),
      ).thenAnswer((_) async => true);
    });

    Future<void> pump(
      WidgetTester tester,
      ShiftListState state, {
      bool canManage = true,
    }) async {
      when(() => cubit.state).thenReturn(state);
      whenListen(
        cubit,
        const Stream<ShiftListState>.empty(),
        initialState: state,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: ShiftScreen(cubit: cubit, canManage: canManage),
        ),
      );
      await tester.pump();
    }

    testWidgets('loads on open and shows skeletons while loading', (
      tester,
    ) async {
      await pump(tester, const ShiftListLoading());

      verify(() => cubit.fetch()).called(1);
      expect(find.byType(ShiftCardSkeleton), findsWidgets);
    });

    testWidgets('empty state invites an admin to add a shift', (tester) async {
      await pump(tester, const ShiftListLoaded([]));

      expect(find.text('Belum ada shift'), findsOneWidget);
      expect(
        find.text('Tambahkan shift untuk mulai menyusun jadwal.'),
        findsOneWidget,
      );
    });

    testWidgets('error state retries', (tester) async {
      await pump(tester, const ShiftListError('Tidak ada koneksi.'));

      expect(find.text('Gagal memuat daftar shift'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      verify(() => cubit.fetch()).called(2);
    });

    testWidgets('shows the details of each shift to an admin', (tester) async {
      await pump(tester, const ShiftListLoaded([_pagi, _malam]));

      expect(find.text('2 shift aktif'), findsOneWidget);
      expect(find.text('Manajemen Shift'), findsOneWidget);
      expect(find.text('07:00–15:00 · 8 jam'), findsOneWidget);
      expect(find.text('Berakhir besok'), findsOneWidget);
      expect(find.textContaining('Radius'), findsNothing);
      expect(find.textContaining('lokasi'), findsNothing);
      expect(find.text('Tambah Shift'), findsOneWidget);
    });

    testWidgets('a member sees the list without any management control', (
      tester,
    ) async {
      await pump(tester, const ShiftListLoaded([_pagi]), canManage: false);

      expect(find.byType(ShiftCard), findsOneWidget);
      expect(find.text('Daftar Shift'), findsOneWidget);
      expect(find.text('Tambah Shift'), findsNothing);
      expect(tester.widget<ShiftCard>(find.byType(ShiftCard)).onTap, isNull);
    });
  });

  group('ShiftFormDialog', () {
    late _MockRepository repository;

    setUpAll(() => registerFallbackValue(_FakeInput()));

    setUp(() => repository = _MockRepository());

    Future<ShiftFormCubit> pump(
      WidgetTester tester, {
      ShiftEntity? initial,
    }) async {
      final cubit = ShiftFormCubit(repository: repository, initial: initial);
      addTearDown(cubit.close);
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(body: ShiftFormDialog(cubit: cubit)),
        ),
      );
      await tester.pump();
      return cubit;
    }

    testWidgets('a new shift shows the fields and no location section', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Nama shift *'), findsOneWidget);
      expect(find.text('Jam mulai *'), findsOneWidget);
      expect(find.text('Jam selesai *'), findsOneWidget);
      expect(find.text('Warna shift'), findsOneWidget);
      expect(find.text('Kuning'), findsOneWidget);
      expect(find.text('Lokasi absen'), findsNothing);
      expect(find.text('Radius absen'), findsNothing);
      expect(
        find.text(
          'Perubahan jam berlaku untuk semua jadwal shift ini, '
          'termasuk yang sudah lewat.',
        ),
        findsNothing,
      );
    });

    testWidgets('saving an empty form shows the validation messages', (
      tester,
    ) async {
      final cubit = await pump(tester);

      await cubit.submit();
      await tester.pump();
      await tester.pump();

      expect(find.text('Nama shift wajib diisi.'), findsOneWidget);
      expect(find.text('Pilih jam mulai.'), findsOneWidget);
      expect(find.text('Pilih jam selesai.'), findsOneWidget);
    });

    testWidgets('a server name conflict appears under the name', (
      tester,
    ) async {
      final cubit = await pump(tester);
      cubit
        ..setName('Shift Siang')
        ..setStartTime(const ShiftClock(15, 0))
        ..setEndTime(const ShiftClock(23, 0));
      when(() => repository.createShift(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure('Nama shift sudah dipakai di grup ini.', 409),
        ),
      );

      await cubit.submit();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Nama shift sudah dipakai di grup ini.'),
        findsOneWidget,
      );
    });

    testWidgets('overnight times show the next-day hint', (tester) async {
      final cubit = await pump(tester);
      cubit
        ..setStartTime(const ShiftClock(22, 0))
        ..setEndTime(const ShiftClock(6, 0));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Berakhir keesokan harinya pukul 06:00 · durasi 8 jam'),
        findsOneWidget,
      );
    });

    testWidgets('editing shows the note about past schedules', (tester) async {
      await pump(tester, initial: _pagi);

      expect(
        find.text(
          'Perubahan jam berlaku untuk semua jadwal shift ini, '
          'termasuk yang sudah lewat.',
        ),
        findsOneWidget,
      );
      expect(find.text('Durasi 8 jam'), findsOneWidget);
    });
  });
  group('ShiftFormDialog.show bottom actions', () {
    late _MockRepository repository;

    setUpAll(() => registerFallbackValue(_FakeInput()));

    setUp(() => repository = _MockRepository());

    Future<void> open(WidgetTester tester, {ShiftEntity? initial}) async {
      final cubit = ShiftFormCubit(repository: repository, initial: initial);
      addTearDown(cubit.close);
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  ShiftFormDialog.show(context, initial: initial, cubit: cubit),
              child: const Text('Buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
    }

    Finder inBottom(String text) => find.descendant(
      of: find.byType(AppPageActions),
      matching: find.text(text),
    );

    testWidgets('a new shift has one Simpan and no Hapus', (tester) async {
      await open(tester);

      expect(find.text('Tambah Shift'), findsOneWidget);
      expect(inBottom('Simpan'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.textContaining('Hapus'), findsNothing);
    });

    testWidgets('editing stacks Simpan above Hapus Shift, both at the bottom', (
      tester,
    ) async {
      await open(tester, initial: _pagi);

      expect(inBottom('Simpan'), findsOneWidget);
      expect(inBottom('Hapus Shift'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Hapus Shift'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Simpan')).dy,
        lessThan(tester.getTopLeft(find.text('Hapus Shift')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Hapus Shift')).dy,
        greaterThan(tester.getSize(find.byType(MaterialApp)).height / 2),
      );
    });

    testWidgets('Hapus Shift asks for confirmation naming the shift', (
      tester,
    ) async {
      await open(tester, initial: _pagi);

      await tester.tap(find.text('Hapus Shift'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Shift Pagi?'), findsOneWidget);
      verifyNever(() => repository.deleteShift(any()));

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.deleteShift(any()));
    });

    testWidgets('confirming deletes; a 409 shows the blocked dialog', (
      tester,
    ) async {
      when(() => repository.deleteShift('a')).thenAnswer(
        (_) async => const Left(
          ServerFailure('Shift masih dipakai di jadwal mendatang.', 409),
        ),
      );
      await open(tester, initial: _pagi);

      await tester.tap(find.text('Hapus Shift'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Hapus'));
      await tester.pumpAndSettle();

      verify(() => repository.deleteShift('a')).called(1);
      expect(find.text('Shift tidak bisa dihapus'), findsOneWidget);
      expect(
        find.text('Shift masih dipakai di jadwal mendatang.'),
        findsOneWidget,
      );
    });

    testWidgets('both buttons are disabled while saving', (tester) async {
      final completer = Completer<Either<Failure, ShiftEntity>>();
      when(
        () => repository.updateShift(any(), any()),
      ).thenAnswer((_) => completer.future);
      await open(tester, initial: _pagi);

      await tester.tap(find.text('Simpan'));
      await tester.pump();

      for (final label in ['Simpan', 'Hapus Shift']) {
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, label))
              .enabled,
          isFalse,
          reason: label,
        );
      }
      completer.complete(const Right(_pagi));
      await tester.pumpAndSettle();
    });
  });
}
