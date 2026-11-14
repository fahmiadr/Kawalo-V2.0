import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/attendance_setting_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/attendance_setting_cubit.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_setting_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;

  setUp(() => repository = MockRepository());

  Future<void> pump(
    WidgetTester tester, {
    String role = 'ADMIN',
    AttendanceSettingEntity? setting,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(
      () => repository.getSetting(),
    ).thenAnswer((_) async => Right(setting ?? attendanceSetting()));
    final cubit = AttendanceSettingCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session(role)),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceSettingScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder value(String text) => find.byWidgetPredicate(
    (w) =>
        w is Text && w.key == const ValueKey('setting_value') && w.data == text,
  );

  Finder inHeader(Finder f) =>
      find.descendant(of: find.byType(AppBar), matching: f);

  Finder inActions(Finder f) =>
      find.descendant(of: find.byType(AppTaskFooter), matching: f);

  testWidgets('shows the value, explanation and a header with only the title', (
    tester,
  ) async {
    await pump(tester);

    expect(value('40%'), findsOneWidget);
    expect(find.textContaining('Makin tinggi makin ketat'), findsOneWidget);
    expect(find.text('Bawaan server: 40%'), findsOneWidget);
    expect(inHeader(find.text('Batas Kemiripan Wajah')), findsOneWidget);
    expect(inHeader(find.text('Simpan')), findsNothing);
    expect(inHeader(find.byType(TextButton)), findsNothing);
  });

  testWidgets('Simpan sits at the bottom and is disabled until changed', (
    tester,
  ) async {
    await pump(tester);

    expect(inActions(find.text('Simpan')), findsOneWidget);
    expect(find.text('Kembalikan ke Bawaan'), findsNothing);

    await tester.tap(find.text('60%'));
    await tester.pumpAndSettle();
    expect(value('60%'), findsOneWidget);

    when(() => repository.saveSetting(60)).thenAnswer(
      (_) async => Right(attendanceSetting(percent: 60, isDefault: false)),
    );
    await tester.tap(inActions(find.text('Simpan')));
    await tester.pumpAndSettle();

    verify(() => repository.saveSetting(60)).called(1);
    expect(find.text('Pengaturan absensi disimpan'), findsOneWidget);
    expect(inActions(find.text('Kembalikan ke Bawaan')), findsOneWidget);
  });

  testWidgets('the hint follows the value', (tester) async {
    await pump(tester, setting: attendanceSetting(percent: 30));
    expect(
      find.text('Longgar: petugas lain lebih mudah lolos'),
      findsOneWidget,
    );

    await tester.tap(find.text('40%'));
    await tester.pumpAndSettle();
    expect(find.text('Seimbang'), findsOneWidget);

    await tester.tap(find.text('70%'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ketat: petugas yang sah bisa lebih sering ditolak'),
      findsOneWidget,
    );
  });

  testWidgets('reset asks for confirmation before restoring the default', (
    tester,
  ) async {
    await pump(
      tester,
      setting: attendanceSetting(
        percent: 55,
        isDefault: false,
        updatedBy: 'admin@kawalo.id',
        updatedAt: '2026-11-12T01:00:00.000Z',
      ),
    );
    expect(find.textContaining('Diubah oleh admin@kawalo.id'), findsOneWidget);
    when(
      () => repository.saveSetting(null),
    ).thenAnswer((_) async => Right(attendanceSetting()));

    await tester.tap(find.text('Kembalikan ke Bawaan'));
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmationDialog), findsOneWidget);
    expect(find.text('Kembalikan ke bawaan server (40%)?'), findsOneWidget);
    verifyNever(() => repository.saveSetting(any()));

    await tester.tap(find.text('Kembalikan'));
    await tester.pumpAndSettle();

    verify(() => repository.saveSetting(null)).called(1);
    expect(find.text('Kembalikan ke Bawaan'), findsNothing);
  });

  testWidgets('cancelling the confirmation changes nothing', (tester) async {
    await pump(
      tester,
      setting: attendanceSetting(percent: 55, isDefault: false),
    );

    await tester.tap(find.text('Kembalikan ke Bawaan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.saveSetting(any()));
  });

  testWidgets('non-admins see the value read-only without actions', (
    tester,
  ) async {
    await pump(tester, role: 'GUARD');

    expect(value('40%'), findsOneWidget);
    expect(
      find.text('Hanya admin yang dapat mengubah pengaturan ini.'),
      findsOneWidget,
    );
    expect(find.byType(AppTaskFooter), findsNothing);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets('a load error offers Coba lagi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(
      () => repository.getSetting(),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal memuat.')));
    final cubit = AttendanceSettingCubit(repository: repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(session('ADMIN')),
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: AttendanceSettingScreen(cubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.byType(AppTaskFooter), findsNothing);

    when(
      () => repository.getSetting(),
    ).thenAnswer((_) async => Right(attendanceSetting()));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(value('40%'), findsOneWidget);
  });
}
